# Azure AKS with Terraform

## Prerequisites
- Azure subscription, `az` CLI logged in (`az login`)
- Terraform >= 1.5

## Deploy
```bash
terraform init
terraform apply -auto-approve
# Save kubeconfig
az aks get-credentials -g ms-aks-rg -n ms-aks-aks --overwrite-existing
kubectl get nodes
```
## Sample App
```bash
kubectl create deploy hello --image=nginxdemos/hello
kubectl expose deploy/hello --port 80 --type LoadBalancer
kubectl get svc hello -w
```
