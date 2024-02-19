FROM ghcr.io/typst/typst:latest

RUN apk --update --no-cache add zola

WORKDIR /personal-site

COPY . .

CMD ["/bin/sh", "./run.sh"]