# syntax=docker/dockerfile:1

FROM node:20-slim AS build

WORKDIR /app

# Native dependencies required by bcrypt/sharp on ARMv7
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

RUN npm ci

COPY . .

# Build client and server separately
RUN npm run build
RUN npm run server:build


FROM node:20-slim AS runtime

WORKDIR /app

ENV NODE_ENV=production

# Native dependencies required by bcrypt/sharp
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        make \
        g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY --from=build /app/dist-server ./dist-server
COPY --from=build /app/server/db/migrations ./dist-server/db/migrations
COPY docker-entrypoint.sh ./docker-entrypoint.sh

RUN chmod +x ./docker-entrypoint.sh

EXPOSE 6168

ENTRYPOINT ["./docker-entrypoint.sh"]

CMD ["node", "dist-server/index.js"]
