FROM docker.msg.team/automotive/alpine

ARG IMAGE_PREFIX=docker.msg.team/automotive/
ARG IMAGE_NAME=nexus
ARG IMAGE_VERSION=

LABEL Author="Dennis Saminathan <dennis.saminathan@msg-global.com>"
LABEL vendor="msg"
LABEL build-date=""
LABEL license="msg"
LABEL app-version="3.14.0-04"

ENV NEXUS_VERSION=3.14.0-04
ENV NEXUS_USERNAME=admin
ENV NEXUS_PASSWORD=admin123
ENV HOST=http://localhost
ENV PORT=8081
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV GROOVY_HOME=/usr/local/groovy-2.5.7
ENV PATH=$PATH:$GROOVY_HOME/bin

RUN apk add curl openssl
RUN apk --update add openjdk8 bash

ADD setup/configscripts/* /tmp/
ADD setup/prepare.sh /tmp/prepare.sh
ADD setup/start.sh /home/appuser/app/start.sh
ADD setup/json/* /tmp/

RUN curl -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output /usr/local/bin/jq --progress-bar
RUN chmod +x /usr/local/bin/jq > /dev/null 2>&1
RUN curl -L http://download.sonatype.com/nexus/3/nexus-$NEXUS_VERSION-unix.tar.gz --progress-bar | tar zxf -
RUN mv /nexus-$NEXUS_VERSION /home/appuser/app/

#RUN curl -L https://bintray.com/artifact/download/groovy/maven/apache-groovy-binary-2.5.7.zip -o /tmp/groovy.zip && \
#cd /usr/local && unzip /tmp/groovy.zip &&  ln -s /usr/local/groovy-2.5.7 groovy
#RUN /usr/local/groovy/bin/groovy -v

RUN chmod +x /tmp/prepare.sh && chmod +x /home/appuser/app/start.sh
RUN /tmp/prepare.sh
RUN chown -R appuser:appuser /home/appuser/data /home/appuser/app

USER appuser

EXPOSE ${PORT}

CMD ["/home/appuser/app/start.sh"]
