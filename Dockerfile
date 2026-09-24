# Use a lightweight Node.js runtime image.
FROM node:22-alpine

# Set the application working directory.
WORKDIR /app

# Copy dependency files first to improve Docker layer caching.
COPY package*.json ./

# Install production dependencies only.
RUN npm ci --omit=dev

# Copy the application source code.
COPY app.js ./

# Run the application as the non-root Node user.
USER node

# Document the port used by the Express application.
EXPOSE 8080

# Start the application.
CMD ["node", "app.js"]
