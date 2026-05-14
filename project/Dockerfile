# ==============================================
# Stage 1: Build the Flutter Web Application
# ==============================================
FROM debian:stable-slim AS build-env

# 1. Install system dependencies needed by Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# 2. Download and Install Flutter SDK
# This clones the stable channel of Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /usr/local/flutter
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# 3. Run Flutter Doctor to pre-load dependencies
RUN flutter doctor -v

# 4. Copy project files and build
WORKDIR /app
COPY . .

# Fetch dependencies and build for web
RUN flutter pub get
RUN flutter build web --release --web-renderer canvaskit

# ==============================================
# Stage 2: Serve the Web Application using Nginx
# ==============================================
FROM nginx:alpine

# Copy built files from Stage 1 to Nginx public folder
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80 to traffic
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
