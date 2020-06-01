FROM opensuse/tumbleweed:latest

WORKDIR /workspace

ENV KU_SKIP_SETUP="true"
ENV KU_FORCE_INSTALL="false"
ENV KU_ZYPPER_INSTALL_OPTS="-y -l"
ENV KU_INSTALL_DIR=/usr/local/lib
ENV KU_INSTALL_BIN=/usr/local/bin
ENV KU_TMP_DIR=/tmp

COPY . /workspace

RUN zypper in -yl sudo curl; \
    ./bin/install.sh init; \
    zypper cc -a

ENTRYPOINT /bin/bash
