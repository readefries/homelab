MQTT (Eclipse Mosquitto) on k3s

Resources in mqtt/k8s:
- namespace.yaml
- configmap.yaml (mosquitto.conf)
- pvc.yaml (persistent data)
- deployment.yaml
- service.yaml (ClusterIP)
- service-lb.yaml (optional LoadBalancer for external access on 1883)

Apply:
ssh root@proxmox "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml && kubectl apply -f /root/homelab/mqtt/k8s"
