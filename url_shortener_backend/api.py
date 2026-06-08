from fastapi import APIRouter, Depends, HTTPException, Request, Response # type: ignore
from fastapi.responses import RedirectResponse # type: ignore
from sqlalchemy.orm import Session # type: ignore
from datetime import datetime, timezone
import qrcode # type: ignore
from io import BytesIO
import logging

import models, schemas, utils # type: ignore
from database import get_db # type: ignore
from tasks import scrape_metadata_task, log_click # type: ignore
from redis_client import redis_client # type: ignore

logger = logging.getLogger("url_shortener.api")
router = APIRouter()

@router.post("/shorten", response_model=schemas.LinkResponse)
def shorten_link(link: schemas.LinkCreate, request: Request, db: Session = Depends(get_db)):
    logger.info(f"Received shortening request for original URL: {link.original_url}")
    
    # Check for custom alias
    if link.custom_alias:
        if not utils.is_valid_alias(link.custom_alias):
            logger.warning(f"Invalid custom alias requested: {link.custom_alias}")
            raise HTTPException(
                status_code=400, 
                detail="Invalid custom alias format. Use alphanumeric characters, underscores, or hyphens (3-32 chars)."
            )
        try:
            existing = db.query(models.Link).filter(models.Link.custom_alias == link.custom_alias).first()
        except Exception as e:
            logger.error(f"Database error during alias check: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Database lookup failed")
            
        if existing:
            logger.warning(f"Alias collision: Custom alias '{link.custom_alias}' already exists")
            raise HTTPException(status_code=400, detail="Custom alias already reserved")
        short_code = link.custom_alias
    else:
        short_code = utils.generate_short_code()
    
    try:
        db_link = models.Link(
            original_url=str(link.original_url),
            short_code=short_code,
            custom_alias=link.custom_alias,
            expiry_time=link.expiry_time
        )
        db.add(db_link)
        db.commit()
        db.refresh(db_link)
    except Exception as e:
        logger.error(f"Database insertion failed for link creation: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Link storage failed")
    
    # Dynamic URL Construction
    base_url = utils.get_base_url(request)
    res = schemas.LinkResponse.model_validate(db_link)
    res.short_url = f"{base_url}/{short_code}"
    res.qr_url = f"{base_url}/qr/{short_code}"

    # Trigger Metadata Enrichment (Async via Celery)
    try:
        scrape_metadata_task.delay(short_code, str(link.original_url))
        logger.info(f"Dispatched metadata scraping Celery task for short code '{short_code}'")
    except Exception as e:
        logger.error(f"Failed to dispatch metadata scraping task to Celery: {e}", exc_info=True)
        # We don't fail the request if Celery is down; the short link is still active

    logger.info(f"Successfully created short code '{short_code}' for URL: {link.original_url}")
    return res

@router.get("/qr/{short_code}")
def get_qr_code(short_code: str, request: Request, db: Session = Depends(get_db)):
    logger.info(f"Generating QR code for short code: '{short_code}'")
    try:
        db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
    except Exception as e:
        logger.error(f"Database lookup failed for QR generation: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Database lookup failed")
        
    if not db_link:
        logger.warning(f"QR code request failed: Short code '{short_code}' not found")
        raise HTTPException(status_code=404, detail="Resource not located")
    
    try:
        qr = qrcode.QRCode(version=1, box_size=10, border=4)
        base_url = utils.get_base_url(request)
        qr_content = f"{base_url}/{short_code}"
        qr.add_data(qr_content)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        buf = BytesIO()
        img.save(buf, format="PNG")  # type: ignore
        logger.info(f"Successfully generated QR PNG image for short code '{short_code}'")
        return Response(content=buf.getvalue(), media_type="image/png")
    except Exception as e:
        logger.error(f"Failed to generate or serialize QR code image: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="QR code generation failed")

@router.get("/{short_code}")
def redirect_to_url(short_code: str, request: Request, db: Session = Depends(get_db)):
    logger.info(f"Redirection request for short code: '{short_code}'")
    target_url = None

    # 1. Try Redis cache
    try:
        cached_url = redis_client.get(short_code)
        if cached_url:
            logger.info(f"Cache hit! Found short code '{short_code}' -> '{cached_url}' in Redis")
            target_url = cached_url
    except Exception as e:
        logger.warning(f"Redis cache lookup failed for '{short_code}': {e}. Falling back to PostgreSQL.")

    if not target_url:
        # 2. Try Database
        try:
            db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        except Exception as e:
            logger.error(f"Database query failed during redirection lookup: {e}", exc_info=True)
            raise HTTPException(status_code=500, detail="Database query error")

        if not db_link:
            logger.warning(f"Redirection failed: Short code '{short_code}' not found")
            raise HTTPException(status_code=404, detail="Link not found")
        
        # Check expiry
        if db_link.expiry_time:
            now = datetime.now(timezone.utc) if db_link.expiry_time.tzinfo else datetime.utcnow()
            if db_link.expiry_time < now:
                logger.warning(f"Expired link hit: Short code '{short_code}' expired at {db_link.expiry_time}")
                raise HTTPException(status_code=410, detail="Link expired")
            
        target_url = db_link.original_url
        logger.info(f"Database lookup complete: Short code '{short_code}' -> '{target_url}'")
        
        # Write to cache
        try:
            if db_link.expiry_time:
                now = datetime.now(timezone.utc) if db_link.expiry_time.tzinfo else datetime.utcnow()
                ttl = int((db_link.expiry_time - now).total_seconds())
                if ttl > 0:
                    redis_client.setex(short_code, ttl, target_url)
            else:
                redis_client.set(short_code, target_url)
            logger.info(f"Saved short code '{short_code}' mapping to Redis cache")
        except Exception as e:
            logger.warning(f"Failed to cache redirection mapping in Redis: {e}")

    # 3. Log analytics (Async via Celery)
    try:
        log_click.delay(
            short_code=short_code, 
            ip=request.client.host if request.client else None, 
            ua=request.headers.get("user-agent"),
            referrer=request.headers.get("referer")
        )
        logger.info(f"Dispatched async click analytics task to Celery for short code '{short_code}'")
    except Exception as e:
        logger.error(f"Failed to dispatch click logging task to Celery: {e}", exc_info=True)
        # Ensure user redirection is not blocked by Celery transport issues

    logger.info(f"Redirecting user for short code '{short_code}' to target URL: {target_url}")
    return RedirectResponse(url=target_url)

@router.get("/{short_code}/stats", response_model=schemas.LinkStats)
def get_link_stats(short_code: str, db: Session = Depends(get_db)):
    logger.info(f"Stats request received for short code: '{short_code}'")
    
    # 1. Attempt Cache Retrieval
    cache_key = f"stats:{short_code}"
    try:
        cached_stats = redis_client.get(cache_key)
        if cached_stats:
            logger.info(f"Cache hit! Found stats for short code '{short_code}' in Redis")
            return schemas.LinkStats.model_validate_json(cached_stats)
    except Exception as e:
        logger.warning(f"Redis stats cache lookup failed: {e}. Querying PostgreSQL.")

    # 2. Database Aggregation
    try:
        db_link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if not db_link:
            logger.warning(f"Stats query failed: Short code '{short_code}' not found")
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
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to aggregate stats for short code '{short_code}' in database: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Stats aggregation failed")
    
    # 3. Persistence to Cache
    try:
        redis_client.setex(cache_key, 60, stats_data.model_dump_json())
        logger.info(f"Persisted aggregated stats for short code '{short_code}' in Redis cache (60s TTL)")
    except Exception as e:
        logger.warning(f"Failed to save aggregated stats to Redis: {e}")
        
    return stats_data
