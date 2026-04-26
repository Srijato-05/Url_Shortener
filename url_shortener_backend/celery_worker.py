from celery import Celery # type: ignore
import os

redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    'tasks',
    broker=redis_url,
    backend=redis_url
)

import models # type: ignore
import user_agents # type: ignore
import utils # type: ignore
from database import SessionLocal # type: ignore

@celery_app.task
def scrape_metadata_task(short_code: str, original_url: str):
    db = SessionLocal()
    try:
        metadata = utils.scrape_metadata(original_url)
        link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if link:
            link.title = metadata.get("title")
            link.description = metadata.get("description")
            link.favicon_url = metadata.get("favicon_url")
            db.commit()
    finally:
        db.close()

@celery_app.task
def log_click(short_code, ip=None, ua=None, referrer=None):
    db = SessionLocal()
    try:
        link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if link:
            # Parse user agent
            parsed_ua = user_agents.parse(ua) if ua else None
            device_type = "Unknown"
            if parsed_ua:
                if parsed_ua.is_bot:
                    device_type = "Bot"
                elif parsed_ua.is_mobile:
                    device_type = "Mobile"
                elif parsed_ua.is_tablet:
                    device_type = "Tablet"
                elif parsed_ua.is_pc:
                    device_type = "PC"
            
            browser = f"{parsed_ua.browser.family} {parsed_ua.browser.version_string}" if parsed_ua else "Unknown"
            os_info = f"{parsed_ua.os.family} {parsed_ua.os.version_string}" if parsed_ua else "Unknown"

            click = models.Click(
                link_id=link.id,
                ip_address=ip,
                user_agent=ua,
                device=device_type,
                browser=browser,
                os_info=os_info,
                location=referrer, 
            )
            db.add(click)
            db.commit()
    finally:
        db.close()
