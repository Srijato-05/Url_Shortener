FROM python:3.12-slim

# Install system dependencies for psycopg2 and other libs
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Set up project directory
WORKDIR /app
COPY . .

# Configure poetry to not create virtualenvs in the container
RUN poetry config virtualenvs.create false

# Synchronize and install dependencies
RUN poetry lock
RUN poetry install --no-interaction --no-ansi

# Expose the API port
EXPOSE 8000

# Start the application using python -m poetry to ensure absolute path safety
CMD ["python", "-m", "poetry", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
