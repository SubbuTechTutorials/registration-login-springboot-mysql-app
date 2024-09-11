# Updated to Spring Boot 3 and Spring Security 8
registration-login-module using springboot, spring mvc, spring security and thymeleaf

http://www.javaguides.net/2018/10/user-registration-module-using-springboot-springmvc-springsecurity-hibernate5-thymeleaf-mysql.html
-------------------------------------------------------------------------------------------------------------------------------------------------
I recently worked on this project where I cloned a this simple Spring Boot application with a MySQL database from GitHub into my local environment. I created a multi-stage Dockerfile for efficient building and deployment.

In Stage 1, the Dockerfile pulls a Maven image with JDK to build the application, and in Stage 2, it uses a lightweight JDK image to run the app by copying the JAR file from the build stage. 

I also set up a MySQL container using the official MySQL image and linked it to the Spring Boot app container with all the necessary environment variables. Once both containers are up, the application is accessible via the browser.

============================================================================================================ 
						Steps to Implement this Project
============================================================================================================
1. Create Dockerfile for Spring Boot Application
As before, create a Dockerfile in your Spring Boot project to build and run the application in a container. 
Here’s an example:
----------------------------------------------
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

Make sure to replace your-app-name.jar with the correct JAR file name.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
2. Build the Docker Image for Spring Boot Application
------------------------------------------------------
docker build -t springboot-app .
--------------------------------------------------------------------------------------------------------------------------------------------------------------
3. Run MySQL Container
------------------------------------------------------
docker run --name mysql-db -e MYSQL_ROOT_PASSWORD=Mysql@123 -e MYSQL_DATABASE=login_system -p 3306:3306 -d mysql:8.0
--------------------------------------------------------------------------------------------------------------------------------------------------------------
4. Run Spring Boot Application Container
-------------------------------------------------------
docker run --name springboot-app --link mysql-db:mysql -e SPRING_DATASOURCE_URL=jdbc:mysql://mysql-db:3306/login_system -e SPRING_DATASOURCE_USERNAME=root -e SPRING_DATASOURCE_PASSWORD=Mysql@123 -p 8080:8080 springboot-app
------------------------
--link mysql-db: Links the MySQL container to your Spring Boot app container.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
5. Accessing the Application
--------------------------------------------------------------------------------
After starting the Spring Boot container, your application should be accessible at http://<IP-of-EC2>:8080. 
It will connect to the MySQL container for database operations.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
6. Stopping and Cleaning Up Containers
docker stop springboot-app mysql-db

To remove them:
docker rm springboot-app mysql-db
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
This setup allows you to run Spring Boot and MySQL containers manually without using Docker Compose. 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


