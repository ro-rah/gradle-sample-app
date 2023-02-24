FROM gradle:4.7.0-jdk8-alpine AS build
ARG SLTOKEN=${SLTOKEN}
ARG APPNAME=${APPNAME}
ARG BRANCH=${BRANCH}
ARG BUILD_NUMBER=${BUILD_NUMBER}
USER root
RUN apk add --no-cache wget
COPY --chown=gradle:gradle . /home/gradle/src
WORKDIR /home/gradle/src
#RUN wget -nv https://agents.sealights.co/sealights-java/sealights-java-latest.zip
#RUN unzip -oq sealights-java-latest.zip
RUN echo '{ \
  "tokenfile": "'$SLTOKEN'", \n\
  "createBuildSessionId": true, \n\
  "appName": "'$APPNAME'", \n\
  "branchName": "'$BRANCH'", \n\
  "buildName": "1.1.'$BUILD_NUMBER'", \n\
  "packagesIncluded": "demo*", \n\
  "includeResources": true, \n\
  "executionType": "full", \n\
  "testStage": "Unit Tests", \n\
  "sealightsJvmParams": { \
    "sl.featuresData.enableLineCoverage": "true" \
  }, \
  "failsafeArgLine": "@{sealightsArgLine} -Dsl.testStage=\"Integration Tests\"" \
}' > slgradle.json
RUN cat slgradle.json
CMD java -jar sl-build-scanner.jar -gradle -configfile slgradle.json -workspacepath "."


#RUN gradle build --no-daemon 

#FROM openjdk:8-jre-slim

#EXPOSE 8080

#RUN mkdir /app

#COPY --from=build /home/gradle/src/build/libs/*.jar /app/spring-boot-application.jar

#ENTRYPOINT ["java", "-XX:+UnlockExperimentalVMOptions", "-XX:+UseCGroupMemoryLimitForHeap", "-Djava.security.egd=file:/dev/./urandom","-jar","/app/spring-boot-application.jar"]

