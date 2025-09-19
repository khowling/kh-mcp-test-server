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

## Testing

Use this for testing `npx @modelcontextprotocol/inspector `


## MCP protocol lifecycle

### capability negotiation handshake & tools discovery

the client sends an `initialize` request to establish the connection and negotiate supported features.  The AI application’s MCP client manager establishes connections to configured servers and stores their capabilities for later use.

Now that the connection is established, the client can discover available tools by sending a tools/list request.  The AI application fetches available tools from all connected MCP servers and combines them into a unified tool registry that the language model can access

Server response

```json
 "capabilities": {
      "tools": {
        "listChanged": true
      },
      "resources": {}
    },
    "serverInfo": {
      "name": "example-server",
      "version": "1.0.0"
    }
```

The client can now execute a tool using the tools/call method


#### Setting up for Oauth2

Token / Refresh template url: /v2.0/token