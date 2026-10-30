#!/usr/bin/env node

import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";

/**
 * Definition of the Perplexity Ask Tool.
 * This tool accepts an array of messages and returns a chat completion response
 * from the Perplexity API, with citations appended to the message if provided.
 */
const PERPLEXITY_ASK_TOOL: Tool = {
  name: "perplexity_ask",
  description:
    "Engages in a conversation using the Perplexity Agent API with live web search. " +
    "Accepts an array of messages (each with a role and content) " +
    "and returns a ask completion response from the Perplexity model.",
  inputSchema: {
    type: "object",
    properties: {
      messages: {
        type: "array",
        items: {
          type: "object",
          properties: {
            role: {
              type: "string",
              description: "Role of the message (e.g., system, user, assistant)",
            },
            content: {
              type: "string",
              description: "The content of the message",
            },
          },
          required: ["role", "content"],
        },
        description: "Array of conversation messages",
      },
    },
    required: ["messages"],
  },
};

// Retrieve the Perplexity API key from environment variables
const PERPLEXITY_API_KEY = process.env.PERPLEXITY_API_KEY;
if (!PERPLEXITY_API_KEY) {
  console.error("Error: PERPLEXITY_API_KEY environment variable is required");
  process.exit(1);
}

/**
 * Performs a request to the Perplexity Agent API (the replacement for Sonar
 * chat completions). Appends citations to the returned answer if they exist.
 *
 * @param {Array<{ role: string; content: string }>} messages - An array of message objects.
 * @returns {Promise<string>} The answer text with appended citations.
 * @throws Will throw an error if the API request fails.
 */
async function performChatCompletion(
  messages: Array<{ role: string; content: string }>
): Promise<string> {
  // Construct the API endpoint URL and request body.
  // System messages move to the top-level `instructions` field; the rest of the
  // conversation goes into `input` as message items.
  // See https://docs.perplexity.ai/docs/agent-api/migrate-from-sonar/how-to
  const url = new URL("https://api.perplexity.ai/v1/agent");
  const instructions = messages
    .filter((m) => m.role === "system")
    .map((m) => m.content)
    .join("\n\n");
  const body = {
    effort: "fast", // Equivalent of the old "sonar-pro" model; web search is on by default
    ...(instructions ? { instructions } : {}),
    input: messages
      .filter((m) => m.role !== "system")
      .map((m) => ({ type: "message", role: m.role, content: m.content })),
  };

  let response;
  try {
    response = await fetch(url.toString(), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${PERPLEXITY_API_KEY}`,
      },
      body: JSON.stringify(body),
    });
  } catch (error) {
    throw new Error(`Network error while calling Perplexity API: ${error}`);
  }

  // Check for non-successful HTTP status
  if (!response.ok) {
    let errorText;
    try {
      errorText = await response.text();
    } catch (parseError) {
      errorText = "Unable to parse error response";
    }
    throw new Error(
      `Perplexity API error: ${response.status} ${response.statusText}\n${errorText}`
    );
  }

  // Attempt to parse the JSON response from the API
  let data;
  try {
    data = await response.json();
  } catch (jsonError) {
    throw new Error(`Failed to parse JSON response from Perplexity API: ${jsonError}`);
  }

  const output: any[] = Array.isArray(data.output) ? data.output : [];

  // Prefer the convenience `output_text` field; otherwise collect the text parts
  // of every message item in `output`
  let messageContent: string =
    typeof data.output_text === "string" && data.output_text
      ? data.output_text
      : output
          .filter((item) => item.type === "message" && Array.isArray(item.content))
          .flatMap((item) => item.content)
          .filter((part: any) => part.type === "output_text" && typeof part.text === "string")
          .map((part: any) => part.text)
          .join("");

  if (!messageContent) {
    throw new Error(
      `Perplexity API returned no answer text (status: ${data.status ?? "unknown"})`
    );
  }

  // Sources come back in `search_results` items; inline [n] markers in the
  // answer refer to the result whose `id` is n
  const sources = output
    .filter((item) => item.type === "search_results" && Array.isArray(item.results))
    .flatMap((item) => item.results)
    .filter((result: any) => result.url);
  if (sources.length > 0) {
    messageContent += "\n\nCitations:\n";
    sources.forEach((result: any, index: number) => {
      messageContent += `[${result.id ?? index + 1}] ${result.url}\n`;
    });
  }

  return messageContent;
}

// Initialize the server with tool metadata and capabilities
const server = new Server(
  {
    name: "example-servers/perplexity-ask",
    version: "0.1.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * Registers a handler for listing available tools.
 * When the client requests a list of tools, this handler returns the Perplexity Ask Tool.
 */
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [PERPLEXITY_ASK_TOOL],
}));

/**
 * Registers a handler for calling a specific tool.
 * Processes requests by validating input and invoking the appropriate tool.
 *
 * @param {object} request - The incoming tool call request.
 * @returns {Promise<object>} The response containing the tool's result or an error.
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  try {
    const { name, arguments: args } = request.params;
    if (!args) {
      throw new Error("No arguments provided");
    }
    switch (name) {
      case "perplexity_ask": {
        if (!Array.isArray(args.messages)) {
          throw new Error("Invalid arguments for perplexity-ask: 'messages' must be an array");
        }
        // Invoke the chat completion function with the provided messages
        const messages = args.messages;
        const result = await performChatCompletion(messages);
        return {
          content: [{ type: "text", text: result }],
          isError: false,
        };
      }
      default:
        // Respond with an error if an unknown tool is requested
        return {
          content: [{ type: "text", text: `Unknown tool: ${name}` }],
          isError: true,
        };
    }
  } catch (error) {
    // Return error details in the response
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error instanceof Error ? error.message : String(error)}`,
        },
      ],
      isError: true,
    };
  }
});

/**
 * Initializes and runs the server using standard I/O for communication.
 * Logs an error and exits if the server fails to start.
 */
async function runServer() {
  try {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Perplexity Ask MCP Server running on stdio");
  } catch (error) {
    console.error("Fatal error running server:", error);
    process.exit(1);
  }
}

// Start the server and catch any startup errors
runServer().catch((error) => {
  console.error("Fatal error running server:", error);
  process.exit(1);
});
