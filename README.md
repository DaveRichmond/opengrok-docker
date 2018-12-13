# A Docker container for OpenGrok!

## OpenGrok release from official source:

Directly downloaded from official source:
https://github.com/oracle/OpenGrok/releases/tag/${RELEASE}

You can learn more about OpenGrok at http://oracle.github.io/opengrok/

The container is available from DockerHub at https://hub.docker.com/r/daverichmond/opengrok/

## Additional info about the container:

* Tomcat 9
* JRE 8 (Required for Opengrok 1.0);
* Configurable reindexing (default every 10 min);

## How to run:

The container exports ports 8080 for OpenGrok.

    docker run -d -v <path/to/your/src>:/src -p 8080:8080 daverichmond/opengrok:latest

The volume mounted to `/src` should contain the projects you want to make searchable (in sub directories). You can use common revision control checkouts (git, svn, etc...) and OpenGrok will make history and blame information available.

By default, the index will be rebuild every ten minutes. You can adjust this time (in Minutes) by passing the `REINDEX` environment variable:

    docker run -d -e REINDEX=30 -v <path/to/your/src>:/src -p 8080:8080 daverichmond/opengrok:latest

Setting `REINDEX` to `0` will disable automatic indexing. You can manually trigger an reindex using docker exec:

    docker exec <container> /scripts/index.sh

Docker compose can also be used. An example docker-compose.yml:
```yaml
version: 3
services:
  grok:
    restart: always
    image: daverichmond/opengrok:latest
    ports:
      - "8080:8080"
    volumes:
      - "<path to source>:/src"
```

## OpenGrok Web-Interface

The container has OpenGrok as default web app installed (accessible directly from `/`). With the above container setup, you can find it running on

http://localhost:8080/

Please note: on first startup, the web interface will display an error until the indexing has been completed. Give it a few minutes and reload.

Enjoy.
