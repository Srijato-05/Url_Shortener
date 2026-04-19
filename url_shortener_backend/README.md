# URL Shortener Backend

## Setup

1. Install PostgreSQL and create database:
   CREATE DATABASE url_db;

2. Update database credentials in database.py

3. Install Redis and run:
   redis-server

4. Install dependencies:
   pip install -r requirements.txt

## Run Backend
uvicorn main:app --reload

## Run Celery Worker
celery -A celery_worker.celery_app worker --loglevel=info

## Test
POST http://localhost:8000/shorten
Body:
{
    "original_url": "https://google.com"
}
