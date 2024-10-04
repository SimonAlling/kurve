FROM node:18.12.0-alpine3.16

WORKDIR /app

COPY package.json package-lock.json ./
COPY elm-tooling.json .
RUN npm ci

COPY elm.json .
COPY elm-watch.json .
COPY review review
COPY tests tests
COPY src src
RUN npm run check-formatting
RUN npm run review
RUN npm run build
RUN npm test
