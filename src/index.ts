import express from "express";
import { randomUUID } from "node:crypto";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js"
import { z } from "zod";
import cors from "cors";

const app = express();
app.use(express.json());
app.use(cors());

// Enable verbose logging
const log = (message: string, ...args: any[]) => {
  console.log(`[${new Date().toISOString()}] ${message}`, ...args);
};

// Map to store transports by session ID
const transports: { [sessionId: string]: StreamableHTTPServerTransport } = {};

// Add a simple health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok',
    timestamp: new Date().toISOString(),
    transports: Object.keys(transports).length
  });
});



// Handle POST requests for client-to-server communication
app.post('/mcp', async (req, res) => {
  log("Received POST request to /mcp", { 
    headers: req.headers,
    body: req.body
  });

  // Check for existing session ID
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  let transport: StreamableHTTPServerTransport;

  if (sessionId && transports[sessionId]) {
    // Reuse existing transport
    log(`Reusing transport for session ${sessionId}`);
    transport = transports[sessionId];
  } else if (!sessionId && isInitializeRequest(req.body)) {
    // New initialization request
    log("Initializing new session");
    transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: () => randomUUID(),
      onsessioninitialized: (sessionId) => {
        log(`Session initialized with ID: ${sessionId}`);
        // Store the transport by session ID
        transports[sessionId] = transport;
      },
      // DNS rebinding protection is disabled by default for backwards compatibility. If you are running this server
      // locally, make sure to set:
      // enableDnsRebindingProtection: false,
      // allowedHosts: ['*'],
    });

    // Clean up transport when closed
    transport.onclose = () => {
      if (transport.sessionId) {
        log(`Closing session ${transport.sessionId}`);
        delete transports[transport.sessionId];
      }
    };
    
    const server = new McpServer({
      name: "weather",
      version: "1.0.0",
      capabilities: {
        resources: {},
        tools: {},
      },
    });
    
    // Register the weather forecast tool
    server.tool(
      "get_forecast",
      "Get weather forecast for a location",
      {
        town: z.string().describe("Town or city name"),
      },
      async ({ town }) => {
        log(`Getting forecast for ${town}`);
        return {
          content: [
            {
              type: "text",
              text: `The weather in ${town} is sunny with a high of 25°C.`,
            },
          ],
        }
      }
    );

    try {
      // Connect to the MCP server
      log("Connecting transport to server");
      await server.connect(transport);
      log("Transport connected successfully");
    } catch (error) {
      log("Error connecting transport to server", error);
      res.status(500).json({
        jsonrpc: '2.0',
        error: {
          code: -32000,
          message: 'Internal server error during connection',
          data: { error: String(error) }
        },
        id: null,
      });
      return;
    }
  } else {
    // Invalid request
    log("Invalid request - no session ID or initialization", { 
      sessionId,
      isInit: isInitializeRequest(req.body)
    });
    res.status(400).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Bad Request: No valid session ID provided',
      },
      id: null,
    });
    return;
  }

  try {
    // Handle the request
    log("Handling request with transport");
    await transport.handleRequest(req, res, req.body);
    log("Request handled successfully");
  } catch (error) {
    log("Error handling request", error);
    res.status(500).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Internal server error while handling request',
        data: { error: String(error) }
      },
      id: req.body?.id || null,
    });
  }
});

// Reusable handler for GET and DELETE requests
const handleSessionRequest = async (req: express.Request, res: express.Response) => {
  log(`Received ${req.method} request to /mcp`);
  
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  if (!sessionId || !transports[sessionId]) {
    log("Invalid or missing session ID", { sessionId });
    res.status(400).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Invalid or missing session ID',
      },
      id: null,
    });
    return;
  }
  
  const transport = transports[sessionId];
  try {
    log(`Handling ${req.method} request for session ${sessionId}`);
    await transport.handleRequest(req, res);
    log("Request handled successfully");
  } catch (error) {
    log("Error handling session request", error);
    res.status(500).json({
      jsonrpc: '2.0',
      error: {
        code: -32000,
        message: 'Internal server error while handling session request',
        data: { error: String(error) }
      },
      id: null,
    });
  }
};

// Handle GET requests for server-to-client notifications via SSE
app.get('/mcp', handleSessionRequest);

// Handle DELETE requests for session termination
app.delete('/mcp', handleSessionRequest);

// Start the server
const PORT = process.env.PORT || 3000;

console.log(`Starting MCP server on PORT ${PORT}`);

app.listen(PORT);