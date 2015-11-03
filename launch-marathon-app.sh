#!/bin/bash
curl -X POST -d @$1 http://127.0.0.1:8080/v2/apps -H 'Content-Type: application/json'
