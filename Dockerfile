# #####################################################################
# Build stage for building the target directory before running tests
# #####################################################################
FROM maven:3.5.4-jdk-8 as builder

MAINTAINER tofung5

# Only copy the necessary to pull only the dependencies from Intuit's registry
ADD ./pom.xml /opt/build/pom.xml
# As some entries in pom.xml refers to the settings, let's keep it same
#ADD ./settings.xml /opt/build/settings.xml

WORKDIR  /opt/build/

# Prepare by downloading dependencies
RUN mvn -B -e -C -T 1C org.apache.maven.plugins:maven-dependency-plugin:3.0.2:go-offline

# Run the full packaging after copying the source
ADD ./src /opt/build/src
RUN mvn package spring-boot:repackage -Dmaven.test.skip=true -B -e -o -T 1C verify


# #####################################################################
# Build stage for running tests from the target directory
# #####################################################################

FROM builder as tests

COPY --from=builder /opt/build/ /opt/build/
COPY --from=builder /root/.m2 /root/.m2
WORKDIR  /opt/build/

CMD mvn test

# #####################################################################
# Build stage with the runtime jar and resources
# #####################################################################
FROM openjdk:8-jre-slim

# Copy from the previous stage
COPY --from=builder /opt/build/target/rest-sample-*.jar /tmp/
COPY --from=builder /opt/build/src/main/resources /runtime/resources

# Just rename the built version
RUN find /tmp -name "*.jar" ! -name "*sources*" ! -name "*javadoc*" -exec cp -t /runtime {} + && \
    mv /runtime/*.jar /runtime/service.jar && \
    rm -f /tmp/*.jar


EXPOSE 8080

# For deployment healthcheck (docker-native)
HEALTHCHECK --interval=1m --retries=10 CMD curl -f http://localhost:8080/v12/ || exit 1

# This is to support HTTPS calls to other services
RUN apt-get update && apt-get install -y curl ca-certificates
RUN update-ca-certificates && \
   mkdir -p /usr/share/ssl/certs && \
   chmod 755 /usr/share/ssl/certs

# What to execute on docker run
ENTRYPOINT sh -c "java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom \
           $JAVA_PARAMS -jar /runtime/service.jar --server.port=8080 $SPRING_BOOT_APP_OPTS"

