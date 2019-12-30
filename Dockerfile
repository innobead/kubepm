# This is used to verify scripts in bin folder
FROM opensuse/tumbleweed
WORKDIR /project

COPY . /project

RUN zypper in -y sudo

ENTRYPOINT /bin/bash
CMD ./bin/setup-dev.sh && \
    ./bin/setup-dev-crio.sh && \
    ./bin/setup-k8s-tools.sh && \
    ./bin/setup-k8s-runtime.sh && \
    ./bin/setup-k8s-tools.sh
