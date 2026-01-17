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

RUN $HOME/pharo Pharo.image eval --save "WAAdmin register: (WACallbackProcessHandler new) at: 'hello'. \
        WAAdmin defaultDispatcher register: ((WARequestHandler new) yourself) at: 'hello'. \
        WAAdmin defaultDispatcher \
            register: (WAComponent subclass: #HelloWorld \
                instanceVariableNames: '' \
                classVariableNames: '' \
                package: 'HelloWorld') \
            asApplicationAt: 'hello'. \
        HelloWorld compile: 'renderContentOn: html html heading: ''Hello World from Seaside!'''. \
        (WAAdmin defaultDispatcher handlerAt: 'hello') preferenceAt: #sessionClass put: WASession. \
        WAAdmin applicationDefaults removeParent: WADevelopmentConfiguration instance."

EXPOSE 8080

HEALTHCHECK --interval=35s --timeout=4s CMD curl --fail --insecure https://localhost:8080/ || exit 1

CMD ["/home/smalltalk/pharo", "Pharo.image", "eval", "ZnZincServerAdaptor startOn: 8080. Smalltalk snapshot: false andQuit: false"]
