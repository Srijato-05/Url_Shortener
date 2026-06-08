import pytest
import models # type: ignore
from tasks import scrape_metadata_task, log_click # type: ignore

def test_scrape_metadata_task_success(db_session, monkeypatch):
    # Seed a link
    link = models.Link(
        original_url="https://www.example.com",
        short_code="meta1"
    )
    db_session.add(link)
    db_session.commit()

    # Mock the database SessionLocal inside the tasks file to use our test session
    monkeypatch.setattr("tasks.SessionLocal", lambda: db_session)

    # Mock the utils.scrape_metadata call
    def mock_scrape(url):
        return {
            "title": "Example Domain",
            "description": "This is a test description",
            "favicon_url": "https://www.example.com/favicon.ico"
        }
    monkeypatch.setattr("utils.scrape_metadata", mock_scrape)

    # Run task synchronously
    scrape_metadata_task("meta1", "https://www.example.com")

    # Verify database updates
    db_session.expire_all()
    updated_link = db_session.query(models.Link).filter(models.Link.short_code == "meta1").first()
    assert updated_link.title == "Example Domain"
    assert updated_link.description == "This is a test description"
    assert updated_link.favicon_url == "https://www.example.com/favicon.ico"

def test_log_click_task_success(db_session, monkeypatch):
    # Seed a link
    link = models.Link(
        original_url="https://www.example.com",
        short_code="click1"
    )
    db_session.add(link)
    db_session.commit()
    db_session.refresh(link)

    # Mock the database SessionLocal inside the tasks file to use our test session
    monkeypatch.setattr("tasks.SessionLocal", lambda: db_session)

    # Run log_click task
    link_id = link.id
    ua_string = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    log_click(
        short_code="click1",
        ip="127.0.0.1",
        ua=ua_string,
        referrer="https://google.com"
    )

    # Verify click record is logged
    db_session.expire_all()
    clicks = db_session.query(models.Click).filter(models.Click.link_id == link_id).all()
    assert len(clicks) == 1
    click = clicks[0]
    assert click.ip_address == "127.0.0.1"
    assert click.device == "PC"
    assert "Chrome" in click.browser
    assert "Windows" in click.os_info
    assert click.location == "https://google.com"
