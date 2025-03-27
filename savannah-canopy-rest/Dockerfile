FROM openjdk:17-jdk-alpine

RUN pwd && ls -ltr

# Copy the JAR file to the root directory in the container
COPY savannah-canopy-rest/target/*.jar app.jar

# Copy application.properties to the root directory in the container
COPY savannah-canopy-rest/src/main/resources/application.properties /application.properties

# Copy data.sql to the root directory in the container
COPY savannah-canopy-rest/src/main/resources/data.sql /data.sql

ENTRYPOINT ["java","-jar","/app.jar"]

# Add a health check (example)
#HEALTHCHECK --interval=30s --timeout=10s CMD curl --fail http://localhost:8080/actuator/health || exit 1