ARG TOMCAT_VERSION="9"
ARG JRE_VERSION="10"

FROM tomcat:${TOMCAT_VERSION}-jre${JRE_VERSION}
MAINTAINER David Richmond <dave@prstat.org>

RUN apt update && \
	apt install -y git \
		subversion mercurial \
		unzip inotify-tools \
		python3-pip build-essential && \
	apt clean

# install universal ctags (not available upstream)
WORKDIR /tmp
RUN apt install -y build-essential autoconf libtool gettext \
		pkg-config && \
	git clone --depth 1 https://github.com/universal-ctags/ctags && \
	cd ctags && \
	./autogen.sh && \
	./configure && \
	make && make install && \
	cd .. && rm -Rf ctags && apt clean

#PREPARING OPENGROK BINARIES AND FOLDERS
ARG OPENGROK_RELEASE="1.1-rc72"
ADD https://github.com/oracle/OpenGrok/releases/download/${OPENGROK_RELEASE}/opengrok-${OPENGROK_RELEASE}.tar.gz /opengrok.tar.gz
RUN tar -zxvf /opengrok.tar.gz && mv opengrok-* /opengrok && \
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

# add our scripts
ADD scripts /scripts
RUN chmod -R +x /scripts

# custom deployment to / with redirect from /source
RUN rm -rf /usr/local/tomcat/webapps/* && \
    python3 -m pip install /opengrok/tools/opengrok-tools.tar.gz && \
    mkdir -p /var/opengrok/etc/ && \
    opengrok-deploy -c /var/opengrok/etc/configuration.xml \
	/opengrok/lib/source.war \
	/usr/local/tomcat/webapps/ROOT.war && \
    mkdir "/usr/local/tomcat/webapps/source" && \
    echo '<% response.sendRedirect("/"); %>' > "/usr/local/tomcat/webapps/source/index.jsp"

# disable all file logging
ADD logging.properties /usr/local/tomcat/conf/logging.properties
RUN sed -i -e 's/Valve/Disabled/' /usr/local/tomcat/conf/server.xml

# export volumes
VOLUME /var/opengrok/data

# run
WORKDIR $CATALINA_HOME
EXPOSE 8080
CMD ["/scripts/start.sh"]
