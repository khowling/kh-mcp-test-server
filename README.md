# Simple MCP Test Server

A minimal TypeScript implementation of an MCP (Model-Context-Protocol) server that exposes a simple HTTP listener to the network using the `@modelcontextprotocol/sdk`.

## Features

- Simple HTTP server that listens on all network interfaces
- MCP server implementation using the official SDK
- Example echo command implementation
- Minimal project structure

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm or yarn

### Installation

```bash
# Install dependencies
npm install
```

### Development

```bash
# Run in development mode
npm run dev
```

### Building and Running

```bash
# Build the project
npm run build

# Run the built project
npm run start
```

## Usage

The server exposes the following endpoints:

- `GET /health` - Health check endpoint
- `POST /mcp` - MCP endpoint for command execution

### Example: Using the Echo Command

Send a POST request to `/mcp` with:

```json
{
  "command": "echo",
  "parameters": {
    "message": "Hello, MCP!"
  }
}
```

Response:

```json
{
  "type": "success",
  "result": {
    "echoed": "Hello, MCP!",
    "timestamp": "2025-09-18T12:34:56.789Z"
  }
}
```

### Getting Command Help

Send a request with the `learn` parameter set to `true`:

```json
{
  "command": "echo",
  "learn": true
}
```

## Configuration

The server can be configured using environment variables:

- `PORT` - The port to listen on (default: 3000)
- `HOST` - The host to bind to (default: 0.0.0.0)

## Adding New Commands

To add a new command, create a new handler class that implements the `MCPHandler` interface:

```typescript
class MyCommandHandler implements MCPHandler {
  readonly command = 'myCommand';
  readonly description = 'Description of my command';
  
  async handle(context: ICommandContext): Promise<any> {
    // Implementation
    return { result: 'some result' };
  }

  help(): any {
    // Help information
    return { ... };
  }
}
```

Then add it to the handlers list when creating the MCP server:

```typescript
const mcpServer = new MCPServer({
  handlers: [
    new EchoCommandHandler(),
    new MyCommandHandler()
  ],
});
```

## License

MIT