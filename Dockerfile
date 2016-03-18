FROM alpine:latest
MAINTAINER cSphere <docker@csphere.cn>

RUN apk add --no-cache --update-cache bash
CMD ["/bin/bash"]
