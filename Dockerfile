# Stage 1: Build the application with Maven
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml ./
RUN mvn dependency:go-offline

# Copy the source code and build the app
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: SonarQube code analysis
FROM sonarsource/sonar-scanner-cli:latest AS sonar-analysis
WORKDIR /app

# Switch to root to manage permissions
USER root

# Create a new 'sonar' user with appropriate permissions
RUN addgroup --system sonar && adduser --system --ingroup sonar sonar

# Create the scanner work directory and set permissions
RUN mkdir -p /app/.scannerwork && chmod -R 777 /app/.scannerwork
RUN mkdir -p /opt/sonar-scanner/.sonar && chmod -R 777 /opt/sonar-scanner/.sonar

# Change ownership of the working directory to 'sonar'
RUN chown -R sonar:sonar /app /opt/sonar-scanner

# Switch to the 'sonar' user
USER sonar

# Set up environment variables
ARG SONARQUBE_HOST
ARG SONARQUBE_TOKEN

# Copy the source code and compiled classes for analysis
COPY --from=build /app/src ./src
COPY --from=build /app/target/classes ./target/classes

# Perform SonarQube analysis
RUN sonar-scanner \
    -Dsonar.projectKey=my-springboot-app \
    -Dsonar.sources=./src \
    -Dsonar.java.binaries=./target/classes \
    -Dsonar.host.url=${SONARQUBE_HOST} \
    -Dsonar.login=${SONARQUBE_TOKEN}

# Stage 3: Copy the built JAR for deployment
FROM openjdk:17-jdk-slim AS release
WORKDIR /app

# Accept the version of the app as a build argument
ARG JAR_FILE_VERSION=0.0.1-SNAPSHOT

# Copy the built JAR from the build stage
COPY --from=build /app/target/registration-login-demo-${JAR_FILE_VERSION}.jar /app/app.jar

# Optional: Push the JAR to Nexus from this stage
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG NEXUS_REPO
RUN curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} \
    --upload-file /app/app.jar \
    ${NEXUS_REPO}/com/example/springboot-app/${JAR_FILE_VERSION}/app.jar

# Stage 4: Final run stage (minimal JDK for running the app)
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy the built JAR from the release stage
COPY --from=release /app/app.jar /app/app.jar

# Expose the application port
EXPOSE 8080

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
