FROM node:22-alpine
WORKDIR /app

COPY app/package.json app/package-lock.json* ./
RUN npm install --omit=dev

COPY app/ ./

ENV PORT=8080
EXPOSE 8080

CMD ["npm", "start"]
