from fastapi import FastAPI # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import os
import logging

# Configure logging format and levels
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("url_shortener")

import models # type: ignore
from database import engine # type: ignore
import api # type: ignore

if os.getenv("TESTING") != "True":
    logger.info("Initializing database tables...")
    models.Base.metadata.create_all(bind=engine)
else:
    logger.info("Skipping database table creation in testing mode.")

app = FastAPI(title="URL Shortener API")

ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

logger.info("Mounting API router...")
app.include_router(api.router)
logger.info("URL Shortener application startup complete.")
