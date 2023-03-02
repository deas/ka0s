#!/bin/sh
kubectl -n litmus patch deployment litmus-server --type='json' -p='[
{"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value": { "name": "ca-certs", "mountPath": "/etc/ssl/certs/ca-certificates.crt", "subPath": "ca-certificates.crt"}}
]'
# {"op": "add", "path": "/spec/template/spec/volumes/-", "value": {"name":"ca-certs", "secret": {"secretName":"ca-certs"}}},

