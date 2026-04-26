from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text # type: ignore
from sqlalchemy.orm import relationship # type: ignore
from sqlalchemy.sql import func # type: ignore
from database import Base # type: ignore

class Link(Base):
    __tablename__ = "links"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=True)
    description = Column(String, nullable=True)
    favicon_url = Column(String, nullable=True)
    original_url = Column(String, nullable=False)
    short_code = Column(String, unique=True, index=True, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expiry_time = Column(DateTime(timezone=True), nullable=True)
    custom_alias = Column(String, unique=True, index=True, nullable=True)

    clicks = relationship("Click", back_populates="link", cascade="all, delete-orphan")

class Click(Base):
    __tablename__ = "clicks"

    id = Column(Integer, primary_key=True, index=True)
    link_id = Column(Integer, ForeignKey("links.id"))
    timestamp = Column(DateTime(timezone=True), server_default=func.now())
    ip_address = Column(String, nullable=True)
    user_agent = Column(Text, nullable=True)
    location = Column(String, nullable=True) # Used for Referrer
    device = Column(String, nullable=True)
    browser = Column(String, nullable=True)
    os_info = Column(String, nullable=True)

    link = relationship("Link", back_populates="clicks")
