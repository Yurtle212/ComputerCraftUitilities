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

    if (wsConnections[channel] == null) {
        wsConnections[channel] = {
            ccConnections: {},
            webConnections: {}
        }
    }

    console.log("\n")
    switch (ws.protocol) {
        case "websiteClient":
            console.log(`Web connection`);
            wsConnections[channel].webConnections[UUID] = {
                channel: channel,
                ws: ws
            };
            break;
        case "ccClient":
            console.log("ComputerCraft Connection");
            wsConnections[channel].ccConnections[UUID] = {
                channel: channel,
                ws: ws
            };
            break;
    }
    console.log(`Channel: ${channel}`)
    console.log(`UUID: ${UUID}`)

    ws.send(JSON.stringify({
        type: "init",
        data: {
            UUID: UUID,
        },
        timestamp: Date.now()
    }))

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
        }
    });
});

app.use(function (req, res, next) {
    res.status(404).send("404");
})

app.listen(port, console.log("Listening on port " + port + "!"));