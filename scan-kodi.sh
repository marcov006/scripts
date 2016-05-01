#!/bin/bash

IP="192.168.0.6"
PORT="80"

curl --data-binary '{ "jsonrpc": "2.0", "method": "VideoLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' http://$IP:$PORT/jsonrpc > /dev/null 2>&1
curl --data-binary '{ "jsonrpc": "2.0", "method": "AudioLibrary.Scan", "id": "mybash"}' -H 'content-type: application/json;' http://$IP:$PORT/jsonrpc > /dev/null 2>&1

