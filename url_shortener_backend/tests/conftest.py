import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient
import os
os.environ["TESTING"] = "True"
import sys

# Ensure backend directory is in the path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import models # type: ignore
from database import Base, get_db # type: ignore
from main import app # type: ignore

# Use a local SQLite database for testing
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

@pytest.fixture(scope="function", autouse=True)
def setup_database():
    # Create tables before each test
    Base.metadata.create_all(bind=engine)
    yield
    # Drop tables after each test to ensure test isolation
    Base.metadata.drop_all(bind=engine)
    engine.dispose()
    try:
        if os.path.exists("./test.db"):
            os.remove("./test.db")
    except Exception:
        pass

@pytest.fixture(scope="function")
def db_session():
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()

@pytest.fixture(scope="function", autouse=True)
def override_dependencies(db_session):
    def _override_get_db():
        try:
            yield db_session
        finally:
            pass
            
    app.dependency_overrides[get_db] = _override_get_db
    yield
    app.dependency_overrides.clear()

@pytest.fixture(scope="function")
def client():
    with TestClient(app) as c:
        yield c



@pytest.fixture(scope="function", autouse=True)
def mock_celery(monkeypatch):
    monkeypatch.setattr("tasks.scrape_metadata_task.delay", lambda *args, **kwargs: None)
    monkeypatch.setattr("tasks.log_click.delay", lambda *args, **kwargs: None)
    monkeypatch.setattr("api.scrape_metadata_task.delay", lambda *args, **kwargs: None)
    monkeypatch.setattr("api.log_click.delay", lambda *args, **kwargs: None)
