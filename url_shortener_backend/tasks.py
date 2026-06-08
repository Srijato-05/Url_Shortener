from typing import Optional
import os
import logging
import user_agents # type: ignore
from celery import Celery # type: ignore
import models, utils # type: ignore
from database import SessionLocal # type: ignore

logger = logging.getLogger("url_shortener.tasks")

redis_url = os.getenv("REDIS_URL", "redis://redis:6379/0")
celery_app = Celery("tasks", broker=redis_url, backend=redis_url)

@celery_app.task
def scrape_metadata_task(short_code: str, original_url: str):
    logger.info(f"Starting metadata scraping for short code '{short_code}' and URL '{original_url}'")
    db = SessionLocal()
    try:
        metadata = utils.scrape_metadata(original_url)
        link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if link:
            link.title = metadata.get("title")
            link.description = metadata.get("description")
            link.favicon_url = metadata.get("favicon_url")
            db.commit()
            logger.info(f"Successfully scraped and updated metadata for short code '{short_code}'")
        else:
            logger.warning(f"Link not found in database for short code '{short_code}' during metadata scraping")
    except Exception as e:
        logger.error(f"Error occurred during metadata scraping for short code '{short_code}': {e}", exc_info=True)
    finally:
        db.close()

@celery_app.task
def log_click(short_code: str, ip: Optional[str] = None, ua: Optional[str] = None, referrer: Optional[str] = None):
    logger.info(f"Logging click redirect for short code '{short_code}'")
    db = SessionLocal()
    try:
        link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if link:
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
            logger.info(f"Successfully logged click redirect analytics for short code '{short_code}'")
        else:
            logger.warning(f"Link not found in database for short code '{short_code}' during click logging")
    except Exception as e:
        logger.error(f"Error occurred during click logging for short code '{short_code}': {e}", exc_info=True)
    finally:
        db.close()
