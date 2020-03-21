FROM alpine:3.11

RUN apk add --update git asciidoctor libc6-compat libstdc++ hugo \
    && apk upgrade \
    && apk add --no-cache ca-certificates

COPY ./hugo.sh /hugo.sh

VOLUME /src
VOLUME /output
CMD ["/hugo.sh"]

