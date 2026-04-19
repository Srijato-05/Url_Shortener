from pydantic import BaseModel, EmailStr, HttpUrl
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    email: EmailStr
    created_at: datetime
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class LinkCreate(BaseModel):
    original_url: HttpUrl
    custom_alias: Optional[str] = None
    expiry_time: Optional[datetime] = None

class LinkResponse(BaseModel):
    id: int
    title: Optional[str]
    original_url: str
    short_code: str
    short_url: Optional[str] = None
    created_at: datetime
    expiry_time: Optional[datetime]
    custom_alias: Optional[str]
    class Config:
        from_attributes = True

class ClickResponse(BaseModel):
    timestamp: datetime
    ip_address: Optional[str]
    device: Optional[str]
    location: Optional[str]
    class Config:
        from_attributes = True

class LinkAnalytics(BaseModel):
    link: LinkResponse
    total_clicks: int
    recent_clicks: List[ClickResponse]
