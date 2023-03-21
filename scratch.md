## Scratch

```shell
ctr --namespace k8s.io containers list
ctr --namespace k8s.io containers info <container-id>
```

```shell
 helm install --values values-loki.yaml loki --namespace=loki grafana/loki-simple-scalable
NAME: loki
LAST DEPLOYED: Sat Mar 18 16:14:51 2023
NAMESPACE: loki
STATUS: deployed
REVISION: 1
NOTES:
***********************************************************************
 Welcome to Grafana Loki
 Chart version: 1.8.11
 Loki version: 2.6.1
***********************************************************************

Installed components:
* gateway
* read
* write

This chart requires persistence and object storage to work correctly.
Queries will not work unless you provide a `loki.config.common.storage` section with
a valid object storage (and the default `filesystem` storage set to `null`), as well
as a valid `loki.config.schema_config.configs` with an `object_store` that
matches the common storage section.

For example, to use MinIO as your object storage backend:

loki:
  config:
    common:
      storage:
        filesystem: null
        s3:
          endpoint: minio.minio.svc.cluster.local:9000
          insecure: true
          bucketnames: loki-data
          access_key_id: loki
          secret_access_key: supersecret
          s3forcepathstyle: true
    schema_config:
      configs:
        - from: "2020-09-07"
          store: boltdb-shipper
          object_store: s3
          schema: v11
          index:
            period: 24h
            prefix: loki_index_
```

```sh
token=$(curl -s 'http://localhost:9091/auth/login' --data-raw '{"username":"admin","password":"admin"}' | jq -r .access_token)
server=http://litmus-server-service:9002
# http://localhost:9091/api

token="eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NzkyNTIyNjMsInJvbGUiOiJhZG1pbiIsInVpZCI6IjA4OGYwNGRhLWM3YWUtNGNlYi04OGJmLWI0ZjFkZWJhYTA5MyIsInVzZXJuYW1lIjoiYWRtaW4ifQ.3GAWEzcNJYFv6Sde1ncYFyUnkL4tqXMqlQehORzKvG9OACSe_ztLFr8WUmx3ZnSwxEvp9biyn2UUxpuw73zCfQ"

curl ${server}/users -H "Accept: application/json" -H "Authorization: Bearer ${token}"


curl http://localhost:9091/api/users \
   -H "Accept: application/json" \
   -H "Authorization: Bearer ${token}"


curl http://localhost:9091/api/users \
   -H "Accept: application/json" \
   -H "Authorization: Bearer ${token}"

# works
curl 'http://localhost:9091/api/query' \
  -H "Cookie: litmus-cc-token=${token}" \
  -H 'content-type: application/json' \
  --data-raw $'{"operationName":"listHubStatus","variables":{"projectID":"85962648-e13b-4417-88ca-150a473cc652"},"query":"query listHubStatus($projectID: String\u0021) {\\n  listHubStatus(projectID: $projectID) {\\n    id\\n    repoURL\\n    repoBranch\\n  }\\n}\\n"}'

curl 'http://localhost:9091/auth/list_projects' \
  -H "Authorization: Bearer ${token}"
``` 
```sh
# litmuschaos/go-runner:2.14.0
kubectl -n litmus run experiment --tty -i --rm --restart=Never --image litmuschaos/go-runner:2.14.0
kubectl -n litmus run foo --tty -i --rm --restart=Never --image litmuschaos/litmus-app-deployer:latest -- -namespace=litmus -typeName=resilient -operation=delete -app=podtato-head

kubectl -n litmus exec -it litmus-server-6475fb78c-p64dl sh
curl http://podtato-main.litmus.svc.cluster.local:9000
```

