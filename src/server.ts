#!/usr/bin/env node

import * as http from "http";
import * as fs from "fs";

import * as parseArgs from "minimist";
import * as yaml from "js-yaml";
import * as ws from "ws";
import * as rpc from "@sourcegraph/vscode-ws-jsonrpc";
import * as rpcServer from "@sourcegraph/vscode-ws-jsonrpc/lib/server";
let url = require('url');
const server = http.createServer();
const axios = require('axios');

process.on('uncaughtException', function (err: any) {
  console.error('Uncaught Exception: ', err.toString());
  if (err.stack) {
    console.error(err.stack);
  }
});

let argv = parseArgs(process.argv.slice(2));
const devLink = 'http://codejudge-core-dev.us-east-1.elasticbeanstalk.com';
const prodLink = 'https://coreapi.codejudge.io';

let coreApi;
let acceptedOrigins;

if (process.env.NODE_ENV === 'production') {
  coreApi = prodLink;
  acceptedOrigins = [
    'recruit.codejudge.io',
    'develop.codejudge.io',
    'interview.codejudge.io',
    'assessment.iquestbee.com',
    'recruit.iquestbee.com'
  ];
}
else {
  coreApi = devLink;
  acceptedOrigins = [
    'codejudge-recruit-dev.s3-website-us-east-1.amazonaws.com',
    'codejudge-web-dev.s3-website-us-east-1.amazonaws.com',
    'codejudge-interviews-dev.s3-website-us-east-1.amazonaws.com',
  ];
}


if (argv.help || !argv.languageServers) {
  console.log(`Usage: server.js --port 3000 --languageServers config.yml`);
  process.exit(1);
}

let serverPort: number = 3000;

let languageServers;
try {
  let parsed = yaml.safeLoad(fs.readFileSync(argv.languageServers), "utf8");
  if (!parsed.langservers) {
    console.error("Your langservers file is not a valid format, see README.md");
    process.exit(1);
  }
  languageServers = parsed.langservers;
} catch (e) {
  console.error(e);
  process.exit(1);
}

const wss: ws.Server = new ws.Server(
  {
    perMessageDeflate: false,
    noServer: true
  },
  () => {
    console.log(`Listening to http and ws requests on ${serverPort}`);
  }
);

server.on('upgrade', async function upgrade(request, socket, head) {
  let args;
  let url_parts = url.parse(request.url, true);
  let query = url_parts.query;
  console.log('Checking for Origin')
  if (request.headers && request.headers.origin && !request.headers.origin.includes('localhost') && !acceptedOrigins.some(link => request.headers.origin.endsWith(link))) {     // Remove localhost After testing
    console.error('Unauthorized Origin:' + request.headers.origin);
    socket.destroy();
    return;
  }
  else if (request.headers && !request.headers.origin) {
    console.error('Unauthorized Origin:' + request.headers.origin);
    socket.destroy();
    return;
  }

  try {
    console.log('Validating User...');
    args = await axios.get(coreApi + '/auth/validate-authority', {
      headers: {
        'Content-Type': 'application/json',
        'cj-header': JSON.stringify({ "sessionId": query.sessionId, "deviceId": query.deviceId, "moduleId": query.moduleId })
      }
    }
    );
    if (args && args.data && args.data.response && !args.data.response.userId) {
      console.error('Guest User not allowed');
      socket.destroy();
      return;
    }
    else {
      console.log('Succesfully Authorized User:' + args.data.response.email + ', Id:' + args.data.response.userId);
    }
  } catch (e) {
    console.error('UnAuthorized User error:', e);
    socket.destroy();
    return;
  }

  wss.handleUpgrade(request, socket, head, function done(ws) {
    console.log('Upgrading to ws from http');
    wss.emit('connection', ws, request);
  });
});

wss.on("connection", (client: ws, request: http.IncomingMessage) => {
  let langServer: string[];
  let url_parts = url.parse(request.url, true);
  let query = url_parts.query;
  Object.keys(languageServers).forEach((key) => {
    if (query.lang === key) {
      langServer = languageServers[key];
    }

  });
  console.log(langServer)

  if (!langServer || !langServer.length) {
    console.error("Invalid language server", query.lang);
    client.close();
    return;
  }
  try {
    let localConnection = rpcServer.createServerProcess(
      "Language Server",
      langServer[0],
      langServer.slice(1)
    );
    let socket: rpc.IWebSocket = toSocket(client);
    let connection = rpcServer.createWebSocketConnection(socket);
    rpcServer.forward(connection, localConnection);
    console.log(`Forwarding new client`);
    socket.onError((error) => {
      console.error('Socket Error: ', error);
    })
    socket.onClose((code, reason) => {
      console.log("Client closed code:", code, " reason:", reason);
      localConnection.dispose();
    });
  } catch (e) {
    console.error("Error Creating Server Process:", e);
  }
});

// Calling Garbage Collection Manually
// function scheduleGc() {
//   if (!global.gc) {
//     console.log('Garbage collection is not exposed');
//     return;
//   }

//   setTimeout(function () {
//     global.gc();    // Cleans gc
//     console.log('Manual GC', process.memoryUsage());
//     scheduleGc();
//   }, 30 * 1000); // 30s Delay
// }
function toSocket(webSocket: ws): rpc.IWebSocket {
  return {
    send: content => webSocket.send(content, error => {
      if (error) {
        console.error("Send toSocket:", error);
        throw error;
      }
    }),
    onMessage: (cb) => (webSocket.onmessage = (event) => cb(event.data)),
    onError: (cb) =>
    (webSocket.onerror = (event) => {
      if ("message" in event) {
        cb((event as any).message);
      }
    }),
    onClose: (cb) =>
      (webSocket.onclose = (event) => cb(event.code, event.reason)),
    dispose: () => webSocket.close(),
  };
}

server.listen(serverPort, null, () => {
  console.log(`Server Started on ${serverPort}`);
})
// scheduleGc(); // First call to gc
