# Ref https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html

#Prerequisites
1. If the OIDC provider doesnt exist in below then add a new one with the listed command

aws eks describe-cluster --name dlp-idb --query "cluster.identity.oidc.issuer" --output text

  eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

eksctl utils associate-iam-oidc-provider --region=ap-south-1 --cluster=dlp-idb --approve

2. If your cluster is 1.21 or later, make sure that your Amazon VPC CNI plugin for Kubernetes, kube-proxy, and CoreDNS add-ons are at the minimum versions listed in ### https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html#boundserviceaccounttoken-validated-add-on-versions

3. Download the policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json

4. 
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

5.

a. Retrieve OIDC and store in a variable

oidc_id=$(aws eks describe-cluster --name my-cluster --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
oidc_id=$(aws eks describe-cluster --name dlp-idb --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

b. Determine OIDC value

aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4

e.g. for dlp-idb cluster value = EAE7AD5A368136534B35C688F7E4F674

c. Add trust policy and save as load-balancer-role-trust-policy.json

Replace the OIDC value from previos step
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::353013733335:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/EAE7AD5A368136534B35C688F7E4F674"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.ap-south-1.amazonaws.com/id/EAE7AD5A368136534B35C688F7E4F674:aud": "sts.amazonaws.com",
                    "oidc.eks.ap-south-1.amazonaws.com/id/EAE7AD5A368136534B35C688F7E4F674:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}

d. Create the IAM role.

aws iam create-role \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --assume-role-policy-document file://"load-balancer-role-trust-policy.json"

e. Attach Policy to Role

aws iam attach-role-policy \
  --policy-arn arn:aws:iam::353013733335:policy/AWSLoadBalancerControllerIAMPolicy \
  --role-name AmazonEKSLoadBalancerControllerRole

f. create file aws-load-balancer-controller-service-account.yaml

apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::353013733335:role/AmazonEKSLoadBalancerControllerRole

6. Create Load Balancer controller using Helm v 3

helm repo add eks https://aws.github.io/eks-charts

helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=dlp-idb \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=my-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

7. Validate

kubectl get deployment -n kube-system aws-load-balancer-controller


aws eks describe-addon --cluster-name dlp-idb --addon-name coredns --query addon.addonVersion --output text

#####2.  COREDNS ##
## Ref# https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html

1.
aws eks describe-addon --cluster-name my-cluster --addon-name coredns --query addon.addonVersion --output text

2.
kubectl describe deployment coredns -n kube-system | grep Image | cut -d ":" -f 3

3. Check CoreDNS image

kubectl describe deployment coredns -n kube-system | grep Image


##### Delete
kubectl delete deployment -n kube-system aws-load-balancer-controller
helm delete aws-load-balancer-controller -n kube-system

eksctl delete iamserviceaccount --cluster=idb-eks-cluster  --namespace=kube-system --name=aws-load-balancer-controller
