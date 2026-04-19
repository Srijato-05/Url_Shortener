from fastapi import FastAPI, Depends, HTTPException, status, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.orm import Session
from datetime import datetime
from typing import Optional

import models, schemas, utils
from database import SessionLocal, engine
from redis_client import redis_client
from celery_worker import log_click
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt

from fastapi.middleware.cors import CORSMiddleware

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Premium URL Shortener API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token", auto_error=False)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def get_current_user(token: Optional[str] = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    if not token:
        return None
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, utils.SECRET_KEY, algorithms=[utils.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except Exception:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == email).first()
    if user is None:
        raise credentials_exception
    return user

@app.post("/register", response_model=schemas.UserResponse)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = utils.get_password_hash(user.password)
    new_user = models.User(email=user.email, password_hash=hashed_password)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form_data.username).first()
    if not user or not utils.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = utils.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/shorten", response_model=schemas.LinkResponse)
def create_link(
    link: schemas.LinkCreate, 
    db: Session = Depends(get_db), 
    current_user: Optional[models.User] = Depends(get_current_user)
):
    # Check for custom alias
    if link.custom_alias:
        existing = db.query(models.Link).filter(models.Link.custom_alias == link.custom_alias).first()
        if existing:
            raise HTTPException(status_code=400, detail="Custom alias already taken")
        short_code = link.custom_alias
    else:
        short_code = utils.generate_short_code()
    
    db_link = models.Link(
        original_url=str(link.original_url),
        short_code=short_code,
        custom_alias=link.custom_alias,
        expiry_time=link.expiry_time,
        user_id=current_user.id if current_user else None
    )
    db.add(db_link)
    db.commit()
    db.refresh(db_link)
    
    # Cache in Redis
    redis_client.set(short_code, str(link.original_url))
    
    # Convert to schema explicitly for host construction
    res = schemas.LinkResponse.model_validate(db_link)
    res.short_url = f"http://localhost:8000/{short_code}"
    return res

@app.get("/{short_code}")
def redirect_to_url(short_code: str, request: Request, db: Session = Depends(get_db)):
    # 1. Try Redis cache
    cached_url = redis_client.get(short_code)
    if cached_url:
        target_url = cached_url.decode('utf-8')
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
        ua=request.headers.get("user-agent")
    )
    
    return RedirectResponse(url=target_url)

@app.get("/analytics/{short_code}", response_model=schemas.LinkAnalytics)
def get_analytics(short_code: str, db: Session = Depends(get_db), current_user: models.User = Depends(get_current_user)):
    db_link = db.query(models.Link).filter(
        models.Link.short_code == short_code,
        models.Link.user_id == current_user.id
    ).first()
    
    if not db_link:
        raise HTTPException(status_code=404, detail="Link not found or unauthorized")
    
    clicks = db.query(models.Click).filter(models.Click.link_id == db_link.id).all()
    
    return {
        "link": schemas.LinkResponse.model_validate(db_link),
        "total_clicks": len(clicks),
        "recent_clicks": clicks[-10:] if clicks else []
    }
