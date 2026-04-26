from fastapi import FastAPI, Depends, HTTPException, status, Request, Response # type: ignore
from fastapi.responses import RedirectResponse # type: ignore
from sqlalchemy.orm import Session # type: ignore
from datetime import datetime, timezone
from typing import Optional
import os
import qrcode # type: ignore
from io import BytesIO

import models, schemas, utils # type: ignore
from database import SessionLocal, engine # type: ignore
from redis_client import redis_client # type: ignore
from celery_worker import log_click, scrape_metadata_task # type: ignore

from fastapi.middleware.cors import CORSMiddleware # type: ignore

import os

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="URL Shortener API")

ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
API_BASE_URL_OVERRIDE = os.getenv("API_BASE_URL")

# Redundant local base_url resolution removed in favor of centralized utils logic.

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.post("/shorten", response_model=schemas.LinkResponse)
def shorten_link(link: schemas.LinkCreate, request: Request, db: Session = Depends(get_db)):
    # Check for custom alias
    if link.custom_alias:
        if not utils.is_valid_alias(link.custom_alias):
            raise HTTPException(
                status_code=400, 
                detail="Invalid custom alias format. Use alphanumeric characters, underscores, or hyphens (3-32 chars)."
            )
        existing = db.query(models.Link).filter(models.Link.custom_alias == link.custom_alias).first()
        if existing:
            raise HTTPException(status_code=400, detail="Custom alias already reserved")
        short_code = link.custom_alias
    else:
        short_code = utils.generate_short_code()
    
    db_link = models.Link(
        original_url=str(link.original_url),
        short_code=short_code,
        custom_alias=link.custom_alias,
        expiry_time=link.expiry_time
    )
    db.add(db_link)
    db.commit()
    db.refresh(db_link)
    
    # Cache in Redis
    redis_client.set(short_code, str(link.original_url))
    
    # Dynamic URL Construction
    base_url = utils.get_base_url(request)
    res = schemas.LinkResponse.model_validate(db_link)
    res.short_url = f"{base_url}/{short_code}"
    res.qr_url = f"{base_url}/qr/{short_code}"

    # 4. Trigger Metadata Enrichment (Async)
    scrape_metadata_task.delay(short_code, str(link.original_url))

    return res

@app.get("/qr/{short_code}")
def get_qr_code(short_code: str, request: Request, db: Session = Depends(get_db)):
    db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
    if not db_link:
        raise HTTPException(status_code=404, detail="Resource not located")
    
    qr = qrcode.QRCode(version=1, box_size=10, border=4)
    # Centralized Dynamic QR content derived from request base
    base_url = utils.get_base_url(request)
    qr_content = f"{base_url}/{short_code}"
    qr.add_data(qr_content)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buf = BytesIO()
    img.save(buf, format="PNG")
    return Response(content=buf.getvalue(), media_type="image/png")

@app.get("/{short_code}")
def redirect_to_url(short_code: str, request: Request, db: Session = Depends(get_db)):
    # 1. Try Redis cache
    cached_url = redis_client.get(short_code)
    if cached_url:
        target_url = cached_url
    else:
        # 2. Try Database
        db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if not db_link:
            raise HTTPException(status_code=404, detail="Link not found")
        
        # Check expiry
        if db_link.expiry_time and db_link.expiry_time < datetime.utcnow():
            raise HTTPException(status_code=410, detail="Link expired")
            
        target_url = db_link.original_url
        redis_client.set(short_code, target_url)

    # 3. Log analytics (Async via Celery)
    log_click.delay(
        short_code=short_code, 
        ip=request.client.host, 
        ua=request.headers.get("user-agent"),
        referrer=request.headers.get("referer")
    )
    
    return RedirectResponse(url=target_url)

@app.get("/{short_code}/stats", response_model=schemas.LinkStats)
def get_link_stats(short_code: str, db: Session = Depends(get_db)):
    # 1. Attempt Cache Retrieval
    cache_key = f"stats:{short_code}"
    cached_stats = redis_client.get(cache_key)
    if cached_stats:
        import json
        return schemas.LinkStats.model_validate_json(cached_stats)

    # 2. Database Aggregation
    db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
    if not db_link:
        raise HTTPException(status_code=404, detail="Resource not located")
    
    total_clicks = db.query(models.Click).filter(models.Click.link_id == db_link.id).count()
    
    from sqlalchemy import func # type: ignore
    device_data = db.query(
        models.Click.device, 
        func.count(models.Click.id)
    ).filter(models.Click.link_id == db_link.id).group_by(models.Click.device).all()
    
    distribution = [
        schemas.DeviceStats(device_type=d[0] or "Unknown", count=d[1]) 
        for d in device_data
    ]
    
    stats_data = schemas.LinkStats(
        total_clicks=total_clicks,
        device_distribution=distribution,
        created_at=db_link.created_at
    )

    # 3. Persistence to Cache
    import json
    redis_client.setex(cache_key, 60, stats_data.model_dump_json())
    
    return stats_data

