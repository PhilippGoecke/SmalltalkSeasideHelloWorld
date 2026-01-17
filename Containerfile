FROM debian:trixie-slim as build-env

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y \
    && apt install -y --no-install-recommends --no-install-suggests curl unzip \
    && apt install -y --no-install-recommends --no-install-suggests build-essential ca-certificates \
    && rm -rf "/var/lib/apt/lists/*" \
    && rm -rf /var/cache/apt/archives

ARG USER=smalltalk
RUN useradd --create-home --shell /bin/bash $USER
ARG HOME="/home/$USER"
WORKDIR $HOME
USER $USER

# Install Pharo Smalltalk
RUN curl -L https://get.pharo.org/64/stable+vm | bash

# Create a Seaside hello world application
RUN $HOME/pharo Pharo.image eval --save "Metacello new \
    baseline: 'Seaside3'; \
    repository: 'github://SeasideSt/Seaside:master/repository'; \
    load."

RUN $HOME/pharo Pharo.image eval --save "WAAdmin unregister: 'hello'. \
    WAAdmin register: [ :request | \
        WAResponse new \
            contentType: 'text/html'; \
            nextPutAll: '<html><body><h1>Hello ', (request at: 'name' ifAbsent: ['World']), ' from Seaside!</h1></body></html>'; \
            yourself ] \
        at: 'hello'. \
    ZnZincServerAdaptor startOn: 8080."

EXPOSE 8080

CMD ["/home/smalltalk/pharo", "Pharo.image", "eval", "ZnZincServerAdaptor startOn: 8080. Smalltalk snapshot: false andQuit: false"]
