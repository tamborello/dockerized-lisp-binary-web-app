FROM ubuntu
MAINTAINER franklin
WORKDIR /bin
COPY . /bin/
EXPOSE 8000
ENV NAME World
CMD ["./app"]
