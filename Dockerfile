# Stage 1: Build the application with Maven
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the source code and build the app
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: SonarQube code analysis
FROM sonarsource/sonar-scanner-cli:latest AS sonar-analysis
WORKDIR /app

# Copy the source code and pom.xml for analysis
COPY --from=build /app/src ./src
COPY --from=build /app/pom.xml ./pom.xml

# Perform SonarQube analysis
ARG SONARQUBE_HOST
ARG SONARQUBE_TOKEN
RUN sonar-scanner \
    -Dsonar.projectKey=my-springboot-app \
    -Dsonar.sources=./src \
    -Dsonar.host.url=${SONARQUBE_HOST} \
    -Dsonar.login=${SONARQUBE_TOKEN}

# Stage 3: Copy the built JAR for deployment
FROM openjdk:17-jdk-slim AS release
WORKDIR /app

# Copy the built JAR from the build stage
COPY --from=build /app/target/registration-login-demo-0.0.1-SNAPSHOT.jar /app/app.jar

# Optional: Push the JAR to Nexus from this stage
ARG NEXUS_USERNAME
ARG NEXUS_PASSWORD
ARG NEXUS_REPO
RUN curl -u ${NEXUS_USERNAME}:${NEXUS_PASSWORD} --upload-file /app/app.jar ${NEXUS_REPO}/com/example/springboot-app/0.0.1/app.jar

# Stage 4: Final run stage (minimal JDK for running the app)
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy the built JAR from the release stage
COPY --from=release /app/app.jar /app/app.jar

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]

