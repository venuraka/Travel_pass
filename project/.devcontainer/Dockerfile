FROM mcr.microsoft.com/vscode/devcontainers/base:ubuntu

# Set shell to Bash
SHELL ["/bin/bash", "-c"]

# Install prerequisites for Flutter Linux/Android
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK for the vscode user
USER vscode
WORKDIR /home/vscode

RUN git clone https://github.com/flutter/flutter.git -b stable /home/vscode/flutter

# Configure Paths for Flutter & Dart
ENV PATH="/home/vscode/flutter/bin:/home/vscode/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Disable Flutter telemetry and pre-download artifacts
RUN flutter config --no-analytics
RUN flutter doctor
