FROM node:22-alpine AS deps

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:22-alpine AS build

WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG API_URL=http://backend:3000
ARG PUBLIC_API_URL=http://localhost:8080
ARG PUBLIC_APP_URL=/app
ARG PUBLIC_MAP_STYLE_URL=https://tiles.openfreemap.org/styles/positron
ARG UMAMI_ID=
ARG UMAMI_URL=

ENV API_URL=$API_URL \
    PUBLIC_API_URL=$PUBLIC_API_URL \
    PUBLIC_APP_URL=$PUBLIC_APP_URL \
    PUBLIC_MAP_STYLE_URL=$PUBLIC_MAP_STYLE_URL \
    UMAMI_ID=$UMAMI_ID \
    UMAMI_URL=$UMAMI_URL

RUN npm run build

FROM node:22-alpine AS runtime

WORKDIR /app
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=4321

COPY --from=build /app/package.json ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

EXPOSE 4321
CMD ["node", "dist/server/entry.mjs"]
