# AWS VPC + ALB + Auto Scaling Group (Terraform)

## Prerequisites
- AWS account, `aws configure` credentials
- Terraform >= 1.5

## Deploy
```bash
terraform init
terraform apply -auto-approve
aws elbv2 describe-load-balancers --query 'LoadBalancers[].DNSName'
```
Open the ALB DNS name in a browser to view the hello page.
