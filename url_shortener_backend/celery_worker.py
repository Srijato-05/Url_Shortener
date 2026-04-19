from celery import Celery
import os

redis_url = os.getenv("REDIS_URL", "redis://localhost:6379/0")

celery_app = Celery(
    'tasks',
    broker=redis_url,
    backend=redis_url
)

import models
from database import SessionLocal

@celery_app.task
def log_click(short_code, ip=None, ua=None):
    db = SessionLocal()
    try:
        link = db.query(models.Link).filter(models.Link.short_code == short_code).first()
        if link:
            click = models.Click(
                link_id=link.id,
                ip_address=ip,
                user_agent=ua
            )
            db.add(click)
            db.commit()
    finally:
        db.close()
