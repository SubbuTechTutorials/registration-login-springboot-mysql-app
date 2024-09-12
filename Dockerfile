# Stage 1: Build the application with Maven
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml ./ 
RUN mvn dependency:go-offline

# Copy the source code and build the app
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Copy the built JAR for deployment
FROM openjdk:17-jdk-slim AS release
WORKDIR /app

# Accept the version of the app as a build argument
ARG JAR_FILE_VERSION=0.0.1-SNAPSHOT

# Copy the built JAR from the build stage
COPY --from=build /app/target/registration-login-demo-${JAR_FILE_VERSION}.jar /app/app.jar

# Stage 3: Final run stage (minimal JDK for running the app)
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy the built JAR from the release stage
COPY --from=release /app/app.jar /app/app.jar

# Expose the application port
EXPOSE 8081

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
