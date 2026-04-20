# URL Shortener Technical Documentation

This project is a full-stack, containerized URL shortening system designed to provide a frictionless user experience while maintaining a robust, scalable backend. It supports both anonymous and authenticated link management, real-time analytics logging through background workers, and a clean, Material 3-based web interface.

## System Architecture

The application is built as a distributed system of four primary services orchestrated via Docker:

1.  Frontend: A Flutter Web application that serves as the entry point for users.
2.  Backend: A FastAPI-based REST API handling core logic and data persistence.
3.  Worker: A Celery background worker for processing high-volume tasks like click logging.
4.  Data Layer: A PostgreSQL database for persistent storage and Redis for message queuing and caching.

### Integration Flow
When a user submits a URL, the frontend sends an asynchronous request to the backend. The backend validates the URL, checks for custom alias availability, and persists the record to PostgreSQL. To minimize latency for the end-user, data-heavy operations like click analytics are offloaded to Redis. The Celery worker then consumes these tasks from Redis and updates the click history in the database without blocking the main request-response cycle.

---

## Backend Implementation

The backend is built with Python 3.12 and FastAPI. It follows a modular design with clear separation between routing, business logic, and data models.

### API Layer
The API defines several key endpoints:
-   Shorten: Accepts a long URL and returns a unique short code. Authentication is optional; providing a JWT token associates the link with a user account, while omitting it creates a public/anonymous link.
-   Redirection: Intercepts hits on shortened codes, triggers a background logging task, and executes a 307 Temporary Redirect to the original destination.
-   Analytics: Provides detailed click-through data for authenticated users.

### Data Modeling and Relations
The system uses SQLAlchemy as its ORM. The relational schema is centered around three primary entities:

-   User Table: Stores identity and authentication data.
-   Link Table: The core of the application. Each link has a one-to-many relationship with the Clicks table and an optional many-to-one relationship with the User table.
-   Click Table: Records metadata for every redirect action, including timestamps, device types, and browser information.

### Asynchronous Pipeline
Click tracking is handled via Celery. When a link is visited, the backend produces an event into a Redis queue. The worker process picks up this event and performs the database write. This ensures that the redirection speed for the visitor is never compromised by slow database performance.

---

## Frontend Implementation

The frontend is a Flutter Web application utilizing Google's Material 3 design system for a sleek, minimalist aesthetic.

### State Management
We use Riverpod for state management. This allows for a reactive UI that updates instantly when a link is created or when the user's link history changes. The `linksProvider` handles the lifecycle of link creation, including error handling and success states.

### Routing
GoRouter handles the navigation within the web app, allowing for a deep-linking capable, URL-addressable frontend.

### User Interface Design
The design prioritizes utility. The landing page features a prominent 'Quick Shorten' tool that supports immediate link generation. Once shortened, the UI presents the result with integrated clipboard support and direct browser-launch capabilities, minimizing the number of steps the user must take.

---

## Deployment and Orchestration

The entire lifecycle is managed through Docker Compose.

### Docker Configuration
-   Backend/Worker: Uses a slim Python 3.12 image. It leverages Poetry for dependency management, ensuring consistent environments across development and production.
-   Frontend: Uses a multi-stage build starting with a Java/Flutter environment to compile the web assets, then serving them via a lightweight web server.

### Environment Configuration
The system relies on several environment variables for service discovery:
-   DATABASE_URL: Link to the PostgreSQL instance.
-   REDIS_URL: Connection string for the Redis queue.

---

## Development Setup

To maintain a clean development environment on your host machine:

### Python Environment
The backend uses Poetry. Navigate to the `url_shortener_backend` directory and run `poetry install`. This creates an isolated virtual environment with all required libraries like FastAPI, SQLAlchemy, and Pydantic.

### IDE Integration (VS Code)
To resolve import paths and eliminate linting errors:
1. Open VS Code in the root directory.
2. Ensure the Python extension is installed.
3. Select the interpreter located at `url_shortener_backend/.venv/Scripts/python.exe`.

### Database Migrations
Models are defined in `models.py`. The application is configured to create tables on startup if they do not exist, facilitating an 'up-and-ready' experience from the first container launch.

---

## Future Roadmap

The system is designed for extensibility. Future iterations could include:
-   Advanced Analytics: Visualizing click trends over time using time-series data.
-   QR Code Generation: Automatically generating downloadable QR codes for every shortened link.
-   API Key Management: Allowing third-party integrations to tap into the shortening engine.
