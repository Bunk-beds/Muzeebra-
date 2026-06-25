FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# Expose port and define persistent volume mount
EXPOSE 3000
VOLUME /data

CMD ["node", "server.js"]
