FROM openjdk:17-jdk-alpine

RUN pwd && ls -ltr

COPY savannah-canopy-rest/target/*.jar app.jar

ENTRYPOINT ["java","-jar","/app.jar"]

# Add a health check (example)
HEALTHCHECK --interval=30s --timeout=10s CMD curl --fail http://localhost:8080/api/payment/health || exit 1