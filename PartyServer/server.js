const WebSocket = require('ws');
const net = require('net');

const wss = new WebSocket.Server({ port: 8080 });
console.log("🟢 WebSocket server running on port 8080");

// TCP connection to Godot
let godotClient = null;

const tcpServer = net.createServer((socket) => {
    console.log("🎮 Godot connected via TCP");
    godotClient = socket;

    socket.on('end', () => {
        console.log("🎮 Godot disconnected");
        godotClient = null;
    });
});

tcpServer.listen(9000, () => {
    console.log("🟢 TCP server for Godot on port 9000");
});

// When phone connects
wss.on('connection', function connection(ws) {
    console.log("📱 Phone connected");

    ws.on('message', function incoming(message) {
        const msg = message.toString();
        console.log("📨 From phone:", msg);

        // Forward to Godot
        if (godotClient) {
            godotClient.write(msg + "\n");
        }
    });
});
