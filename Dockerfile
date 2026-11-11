# Step 1: Use an official Maven image with JDK 17 to build and bundle the app
FROM maven:3.8.6-openjdk-17-slim AS build
WORKDIR /app

# Copy the build configuration and source code
COPY pom.xml .
COPY src ./src

# Pre-fetch dependencies to speed up subsequent image builds
RUN mvn dependency:go-offline -B

# Package the application tests without executing them during image compilation
RUN mvn test-compile

# Step 2: Use a slim runtime image containing Chrome for execution headless environment
FROM openjdk:17-slim
WORKDIR /app

# Install stable Chrome dependencies required for headless Selenium runs
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    unzip \
    libglib2.0-0 \
    libnss3 \
    libgconf-2-4 \
    libfontconfig1 \
    chromium \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled classes and dependencies from the build stage
COPY --from=build /app /app

# Set environment variable to target the internal Chromium binary if needed
ENV CHROME_BIN=/usr/bin/chromium

# Default command to run the TestNG tests inside the container
CMD ["mvn", "test"]
