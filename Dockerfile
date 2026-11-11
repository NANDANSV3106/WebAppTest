# Step 1: Use an official Maven image with Eclipse Temurin JDK 17 to build and cache dependencies
FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the build configuration, TestNG suite, web assets, and source code
COPY pom.xml .
COPY testng.xml .
COPY webpage ./webpage
COPY src ./src

# Pre-fetch dependencies and compile tests
RUN mvn dependency:go-offline -B && mvn test-compile

# Step 2: Use Maven + Eclipse Temurin JDK 17 runtime image with Chromium installed
FROM maven:3.9.9-eclipse-temurin-17
WORKDIR /app

# Install Chromium, Chromium Driver, and headless browser dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    curl \
    unzip \
    libglib2.0-0 \
    libnss3 \
    libfontconfig1 \
    chromium \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled project and cached Maven local repository from the build stage
COPY --from=build /app /app
COPY --from=build /root/.m2 /root/.m2

# Set environment variable for Chromium binary
ENV CHROME_BIN=/usr/bin/chromium

# Default command to run the TestNG tests inside the container
CMD ["mvn", "test"]
