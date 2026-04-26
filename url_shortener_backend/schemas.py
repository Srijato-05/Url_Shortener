from pydantic import BaseModel, EmailStr, HttpUrl, ConfigDict # type: ignore
from typing import Optional, List
from datetime import datetime


class LinkCreate(BaseModel):
    original_url: HttpUrl
    custom_alias: Optional[str] = None
    expiry_time: Optional[datetime] = None

class LinkResponse(BaseModel):
    id: int
    title: Optional[str] = None
    description: Optional[str] = None
    favicon_url: Optional[str] = None
    original_url: str
    short_code: str
    short_url: Optional[str] = None
    created_at: datetime
    expiry_time: Optional[datetime]
    custom_alias: Optional[str]
    qr_url: Optional[str] = None
    class Config:
        from_attributes = True

class ClickResponse(BaseModel):
    timestamp: datetime
    ip_address: Optional[str]
    device: Optional[str]
    location: Optional[str]
    class Config:
        from_attributes = True

class DeviceStats(BaseModel):
    device_type: str
    count: int

class LinkStats(BaseModel):
    total_clicks: int
    device_distribution: List[DeviceStats]
    created_at: datetime

