FROM node:latest

# Create app directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build TypeScript
RUN npm run build

# Expose the MCP server port
EXPOSE 3000

# Start the application
CMD ["npm", "run", "start"]