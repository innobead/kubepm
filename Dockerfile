# This is used to verify scripts in bin folder
FROM opensuse/tumbleweed
WORKDIR /project

COPY bin bin
RUN bin/libs/_common.sh

ENTRYPOINT /bin/bash
CMD tail -f /dev/null