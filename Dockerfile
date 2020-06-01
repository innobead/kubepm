FROM opensuse/leap:15.1

WORKDIR /workspace

ENV KU_SKIP_SETUP="false"
ENV KU_FORCE_INSTALL="false"
ENV KU_ZYPPER_INSTALL_OPTS="-y -l"
#ENV KU_USER=
ENV KU_INSTALL_DIR=/usr/local/lib
ENV KU_INSTALL_BIN=/usr/local/bin
ENV KU_TMP_DIR=/tmp

COPY . /workspace

RUN zypper in -yl sudo; \
    ./bin/install.sh init; \
    zypper cc -a

ENTRYPOINT /bin/bash
