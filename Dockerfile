FROM node:24.10.0-alpine3.22

WORKDIR /app

COPY package.json package-lock.json ./
COPY elm-tooling.json .
RUN npm ci

COPY elm.json .
COPY elm-watch.json .
COPY review review
COPY tools/ScenarioInOriginalGame tools/ScenarioInOriginalGame
COPY tests tests
COPY src src
RUN npm run check-formatting
RUN npm run review
RUN npm run build
RUN npm test
