from datetime import datetime, timedelta
import pytest
import models # type: ignore

def test_shorten_link_success(client):
    response = client.post(
        "/shorten",
        json={"original_url": "https://www.google.com"}
    )
    assert response.status_code == 200
    data = response.json()
    assert "short_code" in data
    assert "short_url" in data
    assert "qr_url" in data
    assert data["original_url"] == "https://www.google.com/"

def test_shorten_link_custom_alias(client):
    response = client.post(
        "/shorten",
        json={"original_url": "https://www.google.com", "custom_alias": "google-home"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["short_code"] == "google-home"
    assert data["short_url"].endswith("/google-home")

def test_shorten_link_invalid_custom_alias(client):
    # Too short
    response = client.post(
        "/shorten",
        json={"original_url": "https://www.google.com", "custom_alias": "go"}
    )
    assert response.status_code == 400
    
    # Invalid characters
    response = client.post(
        "/shorten",
        json={"original_url": "https://www.google.com", "custom_alias": "google!home"}
    )
    assert response.status_code == 400

def test_shorten_link_alias_collision(client):
    response1 = client.post(
        "/shorten",
        json={"original_url": "https://www.google.com", "custom_alias": "myalias"}
    )
    assert response1.status_code == 200
    
    response2 = client.post(
        "/shorten",
        json={"original_url": "https://www.yahoo.com", "custom_alias": "myalias"}
    )
    assert response2.status_code == 400
    assert response2.json()["detail"] == "Custom alias already reserved"

def test_redirect_success(client, db_session):
    # Seed a link
    link = models.Link(
        original_url="https://www.example.com",
        short_code="ex123"
    )
    db_session.add(link)
    db_session.commit()

    response = client.get("/ex123", follow_redirects=False)
    assert response.status_code == 307
    assert response.headers["Location"] == "https://www.example.com"

def test_redirect_not_found(client):
    response = client.get("/missing")
    assert response.status_code == 404

def test_redirect_expired(client, db_session):
    # Seed an expired link
    link = models.Link(
        original_url="https://www.example.com",
        short_code="exp",
        expiry_time=datetime.utcnow() - timedelta(hours=1)
    )
    db_session.add(link)
    db_session.commit()

    response = client.get("/exp")
    assert response.status_code == 410
    assert response.json()["detail"] == "Link expired"

def test_get_qr_code_success(client, db_session):
    # Seed a link
    link = models.Link(
        original_url="https://www.example.com",
        short_code="qr1"
    )
    db_session.add(link)
    db_session.commit()

    response = client.get("/qr/qr1")
    assert response.status_code == 200
    assert response.headers["content-type"] == "image/png"

def test_get_qr_code_not_found(client):
    response = client.get("/qr/missing")
    assert response.status_code == 404

def test_get_stats_success(client, db_session):
    # Seed a link and clicks
    link = models.Link(
        original_url="https://www.example.com",
        short_code="stats1"
    )
    db_session.add(link)
    db_session.commit()
    db_session.refresh(link)

    click1 = models.Click(link_id=link.id, device="PC", browser="Chrome", os_info="Windows")
    click2 = models.Click(link_id=link.id, device="Mobile", browser="Safari", os_info="iOS")
    db_session.add_all([click1, click2])
    db_session.commit()

    response = client.get("/stats1/stats")
    assert response.status_code == 200
    data = response.json()
    assert data["total_clicks"] == 2
    assert len(data["device_distribution"]) == 2
    
    devices = {item["device_type"]: item["count"] for item in data["device_distribution"]}
    assert devices["PC"] == 1
    assert devices["Mobile"] == 1

def test_get_stats_not_found(client):
    response = client.get("/missing/stats")
    assert response.status_code == 404
