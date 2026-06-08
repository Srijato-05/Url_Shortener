# URL Shortener Technical Documentation

This project is a full-stack, containerized URL shortening system designed for a frictionless, anonymous user experience. It supports instant link shortening, custom alias selection, and configurable link expiry—all without requiring accounts or registration.

## System Architecture

The application is built as a simplified, lightweight system of two services orchestrated via Docker:

1.  **Frontend**: A Flutter Web application that serves as the user interface.
2.  **Backend**: A FastAPI-based REST API handling core logic, URL redirection, metadata scraping, and database persistence.

### Integration Flow
When a user submits a URL, the frontend sends an asynchronous request to the backend. The backend validates the URL, checks custom alias availability, and persists the record to an SQLite database. To minimize latency for the end-user, heavy operations like click logging and destination metadata scraping (for titles and favicons) are processed asynchronously using FastAPI's built-in `BackgroundTasks`.

---

## Backend Implementation

The backend is built with Python 3.12 and FastAPI. It follows a modular design with clear separation between routing, business logic, and data models.

### API Layer
The API defines several key endpoints:
-   **Shorten**: Accepts a URL, optional custom alias, and optional expiry time. Returns a unique, absolute short URL.
-   **Redirection**: Intercepts short codes, triggers background click analytics logging, and redirects the user to the destination.

### Data Modeling and Relations
The system uses SQLAlchemy as its ORM. The relational schema is centered around two primary entities:
-   **Link Table**: Stores the mapping between short codes and original URLs, along with expiry and custom alias metadata.
-   **Click Table**: Records telemetry (timestamp, device, etc.) for every redirect.

### Asynchronous Analytics Pipeline
The system captures rich telemetry for every redirection without impacting performance. When a link is visited, the following metadata is logged in the background:
-   **IP Address**: Captured from the request client.
-   **Device Type**: Categorized as Mobile, PC, Tablet, or Bot.
-   **Browser & OS**: Extracted and parsed via the `user-agents` library.
-   **Referrer**: Captured to track the source of the click.
-   **Timestamp**: UTC-aware precise event timing.

These tasks are executed asynchronously by the FastAPI server immediately after sending the redirect response to the client.

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
-   Backend: Uses a slim Python 3.12 image. It leverages Poetry for dependency management, ensuring consistent environments across development and production.
-   Frontend: Uses a multi-stage build starting with a Java/Flutter environment to compile the web assets, then serving them via a lightweight web server.

### Environment Configuration
The system relies on several environment variables for service discovery and behavioral configuration:
-   DATABASE_URL: Link to the SQLite database instance (defaults to `sqlite:///app/data/url_shortener.db` inside the container).
-   API_BASE_URL: The public-facing URL of the API (e.g., `http://localhost:8000`), used to construct absolute short links.
-   ALLOWED_ORIGINS: A comma-separated list of origins permitted to access the API via CORS.

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

## Troubleshooting

### Red Squiggles in IDE (Imports not found)
If VS Code shows errors like `Could not find import for fastapi`, ensure the IDE is using the project's virtual environment:
1. Open a terminal in `url_shortener_backend`.
2. Run `poetry install` to synchronize the environment.
3. In VS Code, press `Ctrl+Shift+P` and select **Python: Select Interpreter**.
4. Choose the path ending in `url_shortener_backend/.venv/Scripts/python.exe`.
5. Run **Developer: Reload Window** to refresh the language server.

### Android Licensing/Gradle Issues
This project is optimized for **Web**. If you encounter Android license errors:
1. Ensure the Android SDK is installed.
2. Run `flutter doctor --android-licenses` and accept all.
3. If Java/Gradle version conflicts occur, verify you are using **Java 17** for the build.
