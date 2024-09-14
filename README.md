In this project, I implemented a fully automated CI/CD pipeline for a Spring Boot application using Jenkins, Docker, MySQL, SonarQube, and Nexus. The pipeline handles every stage of the development lifecycle, from code retrieval to deployment.

Key Stages:
Clone Repo: Fetch latest code from GitHub.
Create Docker Network: Enable container communication.
MySQL Container: Launch MySQL with app-specific DB.
Build App Image: Create a Docker image for the Spring Boot app.
Run App Container: Start the app, connect to MySQL.
Health Check: Verify app status via /actuator/health.
Test Execution: Run unit and integration tests with Maven.
SonarQube Analysis: Perform static code quality checks.
Nexus Deployment: Push JAR artifact to Nexus.
Push Docker Image: Upload the Docker image to a Nexus Docker repo.
Cleanup: Remove unused Docker images.
This automated pipeline ensures smooth continuous integration and delivery, making the development process efficient and reliable.
