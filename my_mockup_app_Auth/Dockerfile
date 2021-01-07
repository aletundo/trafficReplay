FROM node:lts-buster-slim

RUN npm install -g mountebank@2.0.0

RUN apt-get install -y curl

EXPOSE 5000

CMD mb
