FROM alpine:edge

RUN apk add --update git asciidoctor libc6-compat libstdc++ curl tar \
    && apk upgrade \
    && apk add --no-cache ca-certificates

RUN mkdir /tmp/hugo \
    && cd /tmp/hugo \
    && curl -o hugo.tar.gz -L https://github.com/gohugoio/hugo/releases/download/v0.68.1/hugo_0.68.1_Linux-64bit.tar.gz \
    && tar -xf hugo.tar.gz \
    && cp hugo /usr/local/bin/ \
    && rm hugo.tar.gz

COPY ./hugo.sh /hugo.sh

VOLUME /src
VOLUME /output

CMD /hugo.sh
