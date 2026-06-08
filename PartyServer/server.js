const WebSocket = require('ws'); // Vaatii ws-kirjaston (tulee node_modulesista)
const net = require('net');
const http = require('http');
const fs = require('fs');
const path = require('path');

// --- 1. PYTHONIN KORVAAMINEN (HTTP-palvelin portille 8000) ---
const httpServer = http.createServer((req, res) => {
    // Tarjoillaan controller.html riippumatta siitä, mitä polkua puhelin pyytää
    fs.readFile(path.join(__dirname, 'controller.html'), (err, content) => {
        if (err) {
            res.writeHead(500);
            res.end("Virhe ladattaessa ohjainsivua.");
        } else {
            res.writeHead(200, { 'Content-Type': 'text/html; charset=UTF-8' });
            res.end(content, 'utf-8');
        }
    });
});
httpServer.listen(8000, () => {
    console.log("📱 Ohjainsivusto (HTTP) käynnissä portissa 8000");
});

// --- 2. WEBSOCKET-PALVELIN (Puhelimille portti 8080) ---
const wss = new WebSocket.Server({ port: 8080 });
console.log("🟢 WebSocket-palvelin käynnissä portissa 8080");

let godotClient = null;

// --- 3. TCP-PALVELIN (Godotille portti 9000) ---
const tcpServer = net.createServer((socket) => {
    console.log("🎮 Godot yhdistetty TCP:n kautta");
    godotClient = socket;

    socket.on('end', () => {
        console.log("🎮 Godot katkaisi yhteyden");
        godotClient = null;
    });
    socket.on('error', () => { godotClient = null; });
});

tcpServer.listen(9000, () => {
    console.log("🟢 TCP-palvelin Godotille portissa 9000");
});

// Kun puhelin ottaa yhteyden WebSocketilla
wss.on('connection', function connection(ws) {
    console.log("📱 Puhelin yhdistetty");

    ws.on('message', function incoming(message) {
        const msg = message.toString();
        // Nopea välitys Godotille
        if (godotClient) {
            godotClient.write(msg + "\n");
        }
    });
});
