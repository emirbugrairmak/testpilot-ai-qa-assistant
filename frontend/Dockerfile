FROM node:20-alpine

WORKDIR /app

# Bağımlılıkları yükle
COPY package.json package-lock.json* ./
RUN npm install

# Uygulama kodunu kopyala
COPY . .

# Vite dev server — 0.0.0.0 ile container dışından erişilebilir
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "3000"]

EXPOSE 3000
