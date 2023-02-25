FROM gradle:4.7.0-jdk8-alpine AS build
ARG SLTOKEN=${SLTOKEN}
ARG APPNAME=${APPNAME}
ARG BRANCH=${BRANCH}
ARG BUILD_NUMBER=${BUILD_NUMBER}
USER root
RUN apk add --no-cache wget
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
RUN wget -nv https://agents.sealights.co/sealights-java/sealights-java-latest.zip
RUN unzip -oq sealights-java-latest.zip
RUN echo '{ \
  "token": "'$SLTOKEN'", \
  "createBuildSessionId": true, \
  "appName": "'$APPNAME'", \
  "branchName": "'$BRANCH'", \
  "buildName": "1.1.'$BUILD_NUMBER'", \
  "packagesIncluded": "io.codefresh.gradleexample*", \
  "includeResources": true, \
  "executionType": "full", \
  "testStage": "Unit Tests", \
  "sealightsJvmParams": { \
    "sl.featuresData.enableLineCoverage": "true" \
  }, \
  "failsafeArgLine": "@{sealightsArgLine} -Dsl.testStage=\"Unit Tests\"" \
}' > slgradle.json
RUN echo $SLTOKEN > sltoken.txt
RUN cat slgradle.json
RUN java -jar sl-build-scanner.jar -gradle -configfile slgradle.json -workspacepath "."
RUN gradle build --no-daemon 

FROM openjdk:8-jre-slim

EXPOSE 8080

RUN mkdir /app

COPY --from=build /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar

COPY --from=build /home/gradle/src/sl-test-listener.jar /app/
COPY --from=build /home/gradle/src/sltoken.txt /app/
RUN pwd
RUN ls app/

ENTRYPOINT ["java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom", \
"-javaagent:/app/sl-test-listener.jar", "-Dsl.tokenFile=/app/sltoken.txt", "-Dsl.labId=lab1",   "-jar","/app/spring-boot-application.jar"]

