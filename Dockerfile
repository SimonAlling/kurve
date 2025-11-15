FROM node:24.10.0-alpine3.22

WORKDIR /app

COPY package.json package-lock.json ./
COPY elm-tooling.json .
RUN npm ci

COPY elm.json .
COPY elm-watch.json .
COPY review review
COPY tools tools
COPY tests tests
COPY src src
RUN npm run check-formatting
RUN npm run review
RUN npm run build
RUN npm test
RUN DRY_RUN=true ./tools/scenario.py docs/original-game/ZATACKA.EXE 0x7fffd8010ff6 tools/dosbox-linux.conf
RUN DRY_RUN=true ./tools/scenario.py docs/original-game/ZATACKA.EXE 0x7fffc1c65ff6 tools/dosbox-wsl.conf
