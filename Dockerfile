ARG TOMCAT_VERSION="9"
ARG JRE_VERSION="8"

FROM tomcat:${TOMCAT_VERSION}-jre${JRE_VERSION}
MAINTAINER David Richmond <dave@prstat.org>

ARG OPENGROK_RELEASE="1.0"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && \
	apt install -y exuberant-ctags git \
		subversion mercurial \
		unzip inotify-tools

#PREPARING OPENGROK BINARIES AND FOLDERS
ADD https://github.com/oracle/OpenGrok/releases/download/${OPENGROK_RELEASE}/opengrok-${OPENGROK_RELEASE}.tar.gz /opengrok.tar.gz
RUN tar -zxvf /opengrok.tar.gz && mv opengrok-* /opengrok && chmod -R +x /opengrok/bin && \
    mkdir /src && \
    mkdir /data && \
    ln -s /data /var/opengrok && \
    ln -s /src /var/opengrok/src

#ENVIRONMENT VARIABLES CONFIGURATION
ENV SRC_ROOT /src
ENV DATA_ROOT /data
ENV OPENGROK_WEBAPP_CONTEXT /
ENV OPENGROK_TOMCAT_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
ENV PATH /opengrok/bin:$PATH
ENV CATALINA_BASE /usr/local/tomcat
ENV CATALINA_HOME /usr/local/tomcat
ENV CATALINA_TMPDIR /usr/local/tomcat/temp
ENV JRE_HOME /usr
ENV CLASSPATH /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar


# custom deployment to / with redirect from /source
RUN rm -rf /usr/local/tomcat/webapps/* && \
    /opengrok/bin/OpenGrok deploy && \
    mv "/usr/local/tomcat/webapps/source.war" "/usr/local/tomcat/webapps/ROOT.war" && \
    mkdir "/usr/local/tomcat/webapps/source" && \
    echo '<% response.sendRedirect("/"); %>' > "/usr/local/tomcat/webapps/source/index.jsp"

# disable all file logging
ADD logging.properties /usr/local/tomcat/conf/logging.properties
RUN sed -i -e 's/Valve/Disabled/' /usr/local/tomcat/conf/server.xml

# add our scripts
ADD scripts /scripts
RUN chmod -R +x /scripts

# export volumes
VOLUME /var/opengrok/data

# run
WORKDIR $CATALINA_HOME
EXPOSE 8080
CMD ["/scripts/start.sh"]
