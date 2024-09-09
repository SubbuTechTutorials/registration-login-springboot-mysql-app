# Use Maven image to build the app
FROM maven:3.8.4-openjdk-17 AS build
WORKDIR /app

# Copy the pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy the source code and build the app
COPY src ./src
RUN mvn clean package -DskipTests

# Use JDK image for running the app
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy the built JAR from the build image
COPY --from=build /app/target/registration-login-demo-0.0.1-SNAPSHOT.jar /app/app.jar

# Run the Spring Boot application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
