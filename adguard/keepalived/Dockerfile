FROM alpine:3.22
RUN apk add --no-cache keepalived bind-tools
COPY agh_check.sh /usr/local/bin/agh_check.sh
RUN chmod 755 /usr/local/bin/agh_check.sh
CMD ["keepalived", "-n", "-l", "-f", "/etc/keepalived/keepalived.conf"]
