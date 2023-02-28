##### EKS USE A DIFFERENT CLUSTER ###

# List All clusters
eksctl get cluster --region ap-south-1

# Show the Role with EC2
aws sts get-caller-identity

# Show All clusters that have kube-config updated
kubectl config get-clusters

# Update Kubeconfig
aws eks --region ap-south-1 update-kubeconfig --name cluster_name

kubectl get svc

kubectl get nodes




