FROM gradle:4.7.0-jdk8-alpine AS build
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
CMD wget -nv https://agents.sealights.co/sealights-java/sealights-java-latest.zip
CMD unzip -oq sealights-java-latest.zip
CMD echo 
CMD echo '{ \
  "token": "${SLTOKEN}", \
  "createBuildSessionId": true, \
  "appName": "'${JOB_NAME}'", \
  "branchName": "'${BRANCH}'", \
  "buildName": "1.1.'${BUILD_NUMBER}'", \
  "packagesIncluded": "demo*", \
  "includeResources": true, \
  "executionType": "full", \
  "testStage": "Unit Tests", \
  "sealightsJvmParams": { \
    "sl.featuresData.enableLineCoverage": "true" \
  }, \
  "failsafeArgLine": "@{sealightsArgLine} -Dsl.testStage=\"Integration Tests\"" \
}' > slgradle.json
CMD cat slgradle.json
CMD java -jar sl-build-scanner.jar -gradle -configfile slgradle.json -workspacepath "."


RUN gradle build --no-daemon 

FROM openjdk:8-jre-slim

EXPOSE 8080

RUN mkdir /app

COPY --from=build /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar

ENTRYPOINT ["java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom","-jar","/app/spring-boot-application.jar"]

