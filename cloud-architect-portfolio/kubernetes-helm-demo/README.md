# Kubernetes + Helm Demo

Two ways to deploy a minimal web app:
1. Apply raw manifests:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```
2. Use Helm:
```bash
helm install hello ./helm/quickstart-chart
kubectl get pods,svc
```
