FROM ubuntu

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update

RUN apt-get install -y curl nodejs npm

RUN npm install -g npm

RUN npm install -g mountebank

EXPOSE 5000

CMD mb





