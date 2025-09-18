# MCP Test Server

A minimal TypeScript implementation of a Model-Context-Protocol (MCP) server with HTTP listener using the `@modelcontextprotocol/sdk`.

## Project Contents

- **src/index.ts** - MCP server implementation with HTTP listener
- **package.json** - Project dependencies and npm scripts
- **tsconfig.json** - TypeScript configuration
- **Dockerfile** - Container definition for deployment
- **deploy-to-azure.sh** - Script to deploy to Azure Container Instances

## Getting Started

### Local Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build and run for production
npm run build
npm run start
```

### Deployment to Azure

Deploy the MCP server to Azure Container Instances:

```bash
# Deploy with specified ACR, resource group, and version tag
./deploy-to-azure.sh <acr-name> <resource-group> <tag>

# Example
./deploy-to-azure.sh myacr myresourcegroup 1.0.0
```

The deployment script:
1. Builds a container image using the ACR build service (if tag doesn't exist)
2. Creates a resource group if it doesn't exist
3. Deploys as an Azure Container Instance with a custom DNS name

## API Endpoints

- `GET /health` - Health check endpoint
- `POST /mcp` - MCP command execution endpoint

### Example: Echo Command

```json
{
  "command": "echo",
  "parameters": {
    "message": "Hello, MCP!"
  }
}
```

## License

MIT