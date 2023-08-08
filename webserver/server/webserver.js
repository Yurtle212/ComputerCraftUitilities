const express = require('express');
const app = express();
const expressWs = require('express-ws')(app);
const fs = require("fs");
const crypto = require('crypto');

let port = 7510;

app.use(express.static(__dirname));

app.use("/public", express.static("../public/"));
app.use("/js", express.static("../public/js/"));
app.use("/css", express.static("../public/css/"));
app.use("/img", express.static("../public/img/"));

app.get("/:channel", function (req, res) {
    let doc = fs.readFileSync('../public/html/index.html', "utf8");
    res.status(200).send(doc);
})

wsConnections = {}

app.ws('/:channel', function (ws, req) {
    let UUID = crypto.randomUUID();
    let channel = req.params.channel;

    let isWebConnection = ws.protocol == "websiteClient";

    if (wsConnections[channel] == null) {
        wsConnections[channel] = {
            ccConnections: {},
            webConnections: {}
        }
    }

    ws.send(JSON.stringify({
        type: "init",
        data: {
            UUID: UUID,
        },
        timestamp: Date.now()
    }))

    console.log("\n")
    if (isWebConnection) {
        console.log(`Web connection`);
        wsConnections[channel].webConnections[UUID] = {
            channel: channel,
            ws: ws
        };
    } else {
        console.log("ComputerCraft Connection");
        wsConnections[channel].ccConnections[UUID] = {
            channel: channel,
            ws: ws
        };

        sendMsgToAll(channel, "webConnections", {
            type: "ccJoin",
            data: {
                sender: UUID,
            },
            timestamp: Date.now()
        });
    }
    console.log(`Channel: ${channel}`)
    console.log(`UUID: ${UUID}`)

    ws.on('message', function (msg) {
        msg = JSON.parse(msg);
        console.log('\n');
        console.log(`Message from ${UUID}`);
        console.log(`Type: ${msg.type}`);

        if (msg.type == "ping") {
            let ts = Date.now();
            ws.send(JSON.stringify({
                type: "ping",
                data: {
                    travelTime: ts - msg.timestamp
                },
                timestamp: Date.now()
            }))
        } else {
            if (isWebConnection) {
                if (msg.type == "signal") {
                    sendMsgToAll(channel, ["ccConnections", "webConnections"], msg);
                }
                else {
                    sendMsgToAll(channel, ["ccConnections", "webConnections"], msg);
                }
            } else {
                if (msg.type == "ack") {
                    msg.data.UUID = UUID;
                    msg.timestamp = Date.now();
                    sendMsgToAll(channel, ["ccConnections", "webConnections"], msg);
                } else {
                    msg.data.UUID = UUID;
                    msg.timestamp = Date.now();
                    sendMsgToAll(channel, ["ccConnections", "webConnections"], msg);
                }
            }
        }
    });

    ws.on("close", function (msg) {
        sendMsgToAll(channel, "webConnections", {
            type: "other client disconnected",
            data: {
                sender: UUID,
            },
            timestamp: Date.now()
        });
        console.log(`\n${UUID} has disconnected`);

        delete wsConnections[channel].webConnections[UUID];
    })
});

function sendMsgToAll(channel, connTypes, message) {
    if (!Array.isArray(connTypes)) {
        connTypes = [connTypes]
    }

    for (let t in connTypes) {
        let connType = connTypes[t];
        for (let c in wsConnections[channel][connType]) {
            wsConnections[channel][connType][c].ws.send(JSON.stringify(message))
        }
    }
}

app.use(function (req, res, next) {
    res.status(404).send("404");
})

app.listen(port, console.log("Listening on port " + port + "!"));