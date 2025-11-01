# Multi-stage Dockerfile for a Vite React app (build -> static nginx runner)
# Use Node 20 to match modern toolchain requirements
FROM node:20-alpine AS builder
WORKDIR /app

# Install dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# Production stage: serve static files with nginx
FROM nginx:stable-alpine AS runner
# Remove default nginx content and copy built dist
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 for the static site
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
