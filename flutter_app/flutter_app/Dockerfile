# Use eclipse-temurin for a stable and supported Java 17 environment
FROM eclipse-temurin:17-jdk

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$PATH:$FLUTTER_HOME/bin

RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME

# Run basic flutter doctor to initialize
RUN flutter doctor

# Set up project directory
WORKDIR /app
COPY . .

# Get dependencies
RUN flutter pub get

# Build for web with dynamic API_BASE_URL
ARG API_BASE_URL=http://localhost:8000
RUN flutter build web --dart-define=API_BASE_URL=$API_BASE_URL

# We will serve the web app or run it in a way the host can access
# For now, let's use a simple server for the web build
EXPOSE 8080

CMD ["python3", "-m", "http.server", "8080", "--directory", "build/web"]
