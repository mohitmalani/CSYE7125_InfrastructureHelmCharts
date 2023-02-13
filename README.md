# Infrastructure-Helm-Chart

# To install all
`sh helm-install.sh`

# To uninstall all
`sh helm-uninstall.sh`

# Metrics Server
To bring up metrics server:
`kubectl apply -f infra/templates/components.yaml`

To check metrics server running
`kubectl get deploy,svc -n kube-system | egrep metrics-server`
`kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes" `

# Prometheus
To setup Prometheus:
`kubectl create namespace prometheus`
In case repo is not included
`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

To deploy prometheus:
```
helm install prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2" \
    --set-file extraScrapeConfigs=extraScrapeConfigs.yaml
```
Make sure prometheus endpoint in helm response is:
prometheus-server.prometheus.svc.cluster.local

Port forward to access from local:
`kubectl --namespace=prometheus port-forward deploy/prometheus-server 9090`

# Grafana
`kubectl create namespace grafana`

```
helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='EKS!sAWSome' \
    --values infra/templates/grafana.yaml \
    --set service.type=LoadBalancer
```
To Use UI:
Get elestic load balancer external IP

`export ELB=$(kubectl get svc -n grafana grafana -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')`

`echo "http://$ELB"`

Username is "admin"
Password can be fetch from:
`kubectl get secret --namespace grafana grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

# ELK Stack
`kubectl apply -f infra/templates/EFK_namespace.yaml`
`kubectl apply -f infra/templates/elasticsearch.yaml`
`kubectl apply -f infra/templates/fluentd.yaml`
`kubectl apply -f infra/templates/kibana.yaml`

For Kibana dashboard:
`kubectl --namespace=logging port-forward <kibana-pod-name> 5601`

# Kafka/Zookeeper
In case repo is not added:
`helm repo add bitnami https://charts.bitnami.com/bitnami`

to deploy zookeeper:
```
helm install zookeeper bitnami/zookeeper \
  --set replicaCount=3 \
  --set auth.enabled=false \
  --set allowAnonymousLogin=true
```
Make sure zookeeper endpoint in helm response is:
zookeeper.default.svc.cluster.local

to deploy Kafka:
```
helm install kafka bitnami/kafka \
  --set zookeeper.enabled=false \
  --set replicaCount=3 \
  --set externalZookeeper.servers=zookeeper.default.svc.cluster.local
```
Make sure kafka endpoint in helm response is:
zookeeper.default.svc.cluster.local

To create Topic:
```
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=kafka,app.kubernetes.io/instance=kafka,app.kubernetes.io/component=kafka" -o jsonpath="{.items[0].metadata.name}")
```
```
kubectl --namespace default exec -it $POD_NAME -- kafka-topics.sh --create --topic <topic-name> --bootstrap-server localhost:9092 --replication-factor 1 --partitions 2 --config max.message.bytes=64000 --config flush.messages=1
```

To start Kafka message consumer:
```
kubectl --namespace default exec -it $POD_NAME -- kafka-console-consumer.sh --<topic-name> --from-beginning --bootstrap-server localhost:9092 --group <group-name>
```
To start Kafka message producer:
```
kubectl --namespace default exec -it $POD_NAME -- kafka-console-producer.sh --topic <topic-name> --bootstrap-server localhost:9092
```









