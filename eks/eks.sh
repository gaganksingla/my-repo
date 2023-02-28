### STEP 1 - install kubectl
# curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl

# curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.9/2023-01-11/bin/linux/amd64/kubectl.sha256
# openssl sha1 -sha256 kubectl
# chmod +x ./kubectl
# echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
# mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
# kubectl version --short --client

## STEP -1 kubectl download specific kubectl version
curl -LO https://dl.k8s.io/release/v1.24.8/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --short --client


## Step 2- install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

## Step 3- Install jq, envsubst (from GNU gettext utilities) and bash-completion
sudo yum -y install jq gettext bash-completion moreutils

## Step 4 - Install yq for yaml processing
echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

## Step 5 - Verify the binaries are in the path and executable
for command in kubectl jq envsubst aws
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

## Step 6 - Enable kubectl bash_completion
kubectl completion bash >>  ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion

## Step 7 - set the AWS Load Balancer Controller version
echo 'export LBC_VERSION="v2.4.1"' >>  ~/.bash_profile
echo 'export LBC_CHART_VERSION="1.4.1"' >>  ~/.bash_profile
.  ~/.bash_profile

## Step 8- install git, helm
sudo yum install git
export DESIRED_VERSION=v3.9.4
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm version --short

## install kubectl
# curl --silent -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl  > /dev/null

## Step 9 - install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# Step 10 - Create a Role for EC2 as secified in below.
# https://eksctl.io/usage/minimum-iam-policies
# Step 11 - Create Cluster

aws eks create-cluster --region ap-south-1 --name perf-test-eks-cluster --kubernetes-version 1.25 \
   --role-arn arn:aws:iam::353013733335:role/eks-cluster-role \



eksctl create cluster --name=idb-eks-cluster \
                      --region=ap-south-1 \
                      --zones=ap-south-1a,ap-south-1b \
                      --without-nodegroup 

eksctl create cluster --name=idb-eks-cluster \
                      --region=ap-south-1 \
                      --zones=ap-south-1a,ap-south-1b \
                      --without-nodegroup 

eksctl create cluster --name=idb-eks-cluster \
                      --region=ap-south-1 \
                      --zones=ap-south-1a,ap-south-1b \
                      --without-nodegroup

eksctl create cluster --name=perf-test-eks-cluster \
                      --region=ap-south-1 \
                      --zones=ap-south-1a,ap-south-1b \
                      --without-nodegroup
# Step 12- Get List of clusters
eksctl get cluster 
# validate cluster
kubectl cluster-info
## Create OIDC Provider
eksctl utils associate-iam-oidc-provider \
    --region ap-south-1 \
    --cluster idb-eks-cluster \
    --approve
# Step 13- Create Public Node Group   
eksctl create nodegroup --cluster=idb-eks-cluster \
                       --region=ap-south-1 \
                       --name=idb-eks-cluster-ng \
                       --node-type=t3.xlarge \
                       --nodes=3 \
                       --nodes-min=3 \
                       --nodes-max=6 \
                       --node-volume-size=100 \
                       --ssh-access \
                       --ssh-public-key=integration-key \
                       --managed

# Step 14- view nodes
kubectl get nodes -o wide

# Step 15 - Add below permissions to NodeGroup Role. -- This is needed for CSI Driver to create PV, PVC
# Check the Role and Map if not already annotated. Should annotated for both of the below
  kubectl describe configmap -n kube-system aws-auth
  kubectl describe sa ebs-csi-controller-sa -n kube-system
  kubectl describe sa   aws-load-balancer-controller-serviceaccount -n kube-system
  kubectl describe sa   aws-load-balancer-controller -n kube-system

#1. Get OIDC Provider
aws eks describe-cluster --name idb-eks-cluster --query "cluster.identity.oidc.issuer" --output text

aws eks describe-cluster --name dlp-idb --query "cluster.identity.oidc.issuer" --output text

#2. Associate below Trust Policy (Replace the OIDC Provider from above step)
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "ec2.amazonaws.com"
#             },
#             "Action": "sts:AssumeRole"
#         },
#         {
#             "Effect": "Allow",
#             "Principal": {
#                 "Federated": "arn:aws:iam::353013733335:oidc-provider/oidc.eks.ap-south-1.amazonaws.com/id/EA341A248AD705195C5D79A7B7D25E48"
#             },
#             "Action": "sts:AssumeRoleWithWebIdentity",
#             "Condition": {
#                 "StringEquals": {
#                     "oidc.eks.ap-south-1.amazonaws.com/id/EA341A248AD705195C5D79A7B7D25E48:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
#                 }
#             }
#         }
#     ]
# }

#3 Add below Policies to the NodeGroup Role if not already Present
#AmazonEC2RoleforSSM, AmazonEKSWorkerNodePolicy, AmazonEC2ContainerRegistryReadOnly, AmazonSSMManagedInstanceCore, AmazonEC2ContainerRegistryPowerUser, AmazonEKS_CNI_Policy, AmazonEKS_EBS_CSI_Driver_Policy
# 4.Create a New Policy (or if this exists attach this - eksctl-idb-eks-cluster-nodegroup-PolicyAWSLoadBalancerController)

# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Condition": {
#                 "StringEquals": {
#                     "ec2:CreateAction": "CreateSecurityGroup"
#                 },
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             },
#             "Action": [
#                 "ec2:CreateTags"
#             ],
#             "Resource": "arn:aws:ec2:*:*:security-group/*",
#             "Effect": "Allow"
#         },
#         {
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             },
#             "Action": [
#                 "ec2:CreateTags",
#                 "ec2:DeleteTags"
#             ],
#             "Resource": "arn:aws:ec2:*:*:security-group/*",
#             "Effect": "Allow"
#         },
#         {
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             },
#             "Action": [
#                 "elasticloadbalancing:CreateLoadBalancer",
#                 "elasticloadbalancing:CreateTargetGroup"
#             ],
#             "Resource": "*",
#             "Effect": "Allow"
#         },
#         {
#             "Condition": {
#                 "Null": {
#                     "aws:RequestTag/elbv2.k8s.aws/cluster": "true",
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             },
#             "Action": [
#                 "elasticloadbalancing:AddTags",
#                 "elasticloadbalancing:RemoveTags"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"
#             ],
#             "Effect": "Allow"
#         },
#         {
#             "Action": [
#                 "elasticloadbalancing:AddTags",
#                 "elasticloadbalancing:RemoveTags"
#             ],
#             "Resource": [
#                 "arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*",
#                 "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"
#             ],
#             "Effect": "Allow"
#         },
#         {
#             "Condition": {
#                 "Null": {
#                     "aws:ResourceTag/elbv2.k8s.aws/cluster": "false"
#                 }
#             },
#             "Action": [
#                 "ec2:AuthorizeSecurityGroupIngress",
#                 "ec2:RevokeSecurityGroupIngress",
#                 "ec2:DeleteSecurityGroup",
#                 "elasticloadbalancing:ModifyLoadBalancerAttributes",
#                 "elasticloadbalancing:SetIpAddressType",
#                 "elasticloadbalancing:SetSecurityGroups",
#                 "elasticloadbalancing:SetSubnets",
#                 "elasticloadbalancing:DeleteLoadBalancer",
#                 "elasticloadbalancing:ModifyTargetGroup",
#                 "elasticloadbalancing:ModifyTargetGroupAttributes",
#                 "elasticloadbalancing:DeleteTargetGroup"
#             ],
#             "Resource": "*",
#             "Effect": "Allow"
#         },
#         {
#             "Action": [
#                 "elasticloadbalancing:RegisterTargets",
#                 "elasticloadbalancing:DeregisterTargets"
#             ],
#             "Resource": "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*",
#             "Effect": "Allow"
#         },
#         {
#             "Action": [
#                 "iam:CreateServiceLinkedRole",
#                 "ec2:DescribeAccountAttributes",
#                 "ec2:DescribeAddresses",
#                 "ec2:DescribeAvailabilityZones",
#                 "ec2:DescribeInternetGateways",
#                 "ec2:DescribeVpcs",
#                 "ec2:DescribeSubnets",
#                 "ec2:DescribeSecurityGroups",
#                 "ec2:DescribeInstances",
#                 "ec2:DescribeNetworkInterfaces",
#                 "ec2:DescribeTags",
#                 "ec2:DescribeVpcPeeringConnections",
#                 "elasticloadbalancing:DescribeLoadBalancers",
#                 "elasticloadbalancing:DescribeLoadBalancerAttributes",
#                 "elasticloadbalancing:DescribeListeners",
#                 "elasticloadbalancing:DescribeListenerCertificates",
#                 "elasticloadbalancing:DescribeSSLPolicies",
#                 "elasticloadbalancing:DescribeRules",
#                 "elasticloadbalancing:DescribeTargetGroups",
#                 "elasticloadbalancing:DescribeTargetGroupAttributes",
#                 "elasticloadbalancing:DescribeTargetHealth",
#                 "elasticloadbalancing:DescribeTags",
#                 "cognito-idp:DescribeUserPoolClient",
#                 "acm:ListCertificates",
#                 "acm:DescribeCertificate",
#                 "iam:ListServerCertificates",
#                 "iam:GetServerCertificate",
#                 "waf-regional:GetWebACL",
#                 "waf-regional:GetWebACLForResource",
#                 "waf-regional:AssociateWebACL",
#                 "waf-regional:DisassociateWebACL",
#                 "wafv2:GetWebACL",
#                 "wafv2:GetWebACLForResource",
#                 "wafv2:AssociateWebACL",
#                 "wafv2:DisassociateWebACL",
#                 "shield:GetSubscriptionState",
#                 "shield:DescribeProtection",
#                 "shield:CreateProtection",
#                 "shield:DeleteProtection",
#                 "ec2:AuthorizeSecurityGroupIngress",
#                 "ec2:RevokeSecurityGroupIngress",
#                 "ec2:CreateSecurityGroup",
#                 "elasticloadbalancing:CreateListener",
#                 "elasticloadbalancing:DeleteListener",
#                 "elasticloadbalancing:CreateRule",
#                 "elasticloadbalancing:DeleteRule",
#                 "elasticloadbalancing:SetWebAcl",
#                 "elasticloadbalancing:ModifyListener",
#                 "elasticloadbalancing:AddListenerCertificates",
#                 "elasticloadbalancing:RemoveListenerCertificates",
#                 "elasticloadbalancing:ModifyRule"
#             ],
#             "Resource": "*",
#             "Effect": "Allow"
#         }
#     ]
# }

### Step 16 - Adding permission to Create PVC
## Refer https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver --region ap-south-1

eksctl create addon --name aws-ebs-csi-driver --cluster dlp-idb --region ap-south-1 --service-account-role-arn arn:aws:iam::353013733335:role/eks-node-role --force
eksctl get addon --name aws-ebs-csi-driver --cluster dlp-idb 

## Step 17 - If facing issue for ELB / SVC - ELB goes in Pending state
#1 - Create New Policy in ##Policy and name as AWSLoadBalancerControllerIAMPolicy
# Refer links - 
#https://aws.amazon.com/premiumsupport/knowledge-center/eks-load-balancer-webidentityerr/
# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/installation/

##Policy
# curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.1/docs/install/iam_policy.json

#2 - Create a Service Account if not already existing
# eksctl create iamserviceaccount \
# --cluster=<cluster-name> \
# --namespace=kube-system \
# --name=aws-load-balancer-controller \
# --attach-policy-arn=arn:aws:iam::353013733335:policy/AWSLoadBalancerControllerIAMPolicy \
# --override-existing-serviceaccounts \
# --approve

eksctl create iamserviceaccount \
--cluster=idb-eks-cluster \
--namespace=kube-system \
--name=aws-load-balancer-controller \
--attach-policy-arn=arn:aws:iam::353013733335:policy/AWSLoadBalancerControllerIAMPolicy \
--override-existing-serviceaccounts \
--approve

# 3 - Add a Trust Relationship to Node role

#4 - Install load balancer controller
# Refer https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/installation/
helm repo add eks https://aws.github.io/eks-charts

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"

## Replace Cluster name and Service acount = false
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=idb-eks-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

## OPTIONAL - TO DELETE CLUSTER - STEP 18
# If you need to delete and recreate an AddOn delete with below command
#eksctl delete addon --cluster dlp-eks-cluster --name aws-ebs-csi-driver

##### End of EKS Setup steps

#delete cluster 

eksctl delete cluster --name idb-eks-cluster --region ap-south-1


## Metrics Server

kubectl get deployment metrics-server -n kube-system


### Roles
1. eks-cluster-role
Service - EKS -> EKS - Cluster
Policies - AmazonEKSClusterPolicy
2. eks-node-role
Service - EC2
Policies -
    AmazonEKSWorkerNodePolicy, 
    AmazonEC2ContainerRegistryReadOnly,
    AmazonEKS_CNI_Policy

## Create PV StatefulSet EBS or EFS
https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/

aws eks describe-cluster --name dlp-eks-cluster --query "cluster.identity.oidc.issuer" --output text

aws eks describe-cluster --name idb-eks-cluster --query "cluster.identity.oidc.issuer" --output text

## Deploy metrics server After launching    
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.6.1/components.yaml
kubectl get apiservice v1beta1.metrics.k8s.io -o json | jq '.status'


## Deploy kube ops view
mkdir $HOME/environment/kube-ops-view
for file in kustomization.yaml rbac.yaml deployment.yaml service.yaml; do mkdir -p $HOME/environment/kube-ops-view/; curl "https://raw.githubusercontent.com/awslabs/ec2-spot-workshops/master/content/karpenter/040_k8s_tools/k8_tools.files/kube_ops_view/${file}" > $HOME/environment/kube-ops-view/${file}; done
kubectl apply -k $HOME/environment/kube-ops-view

kubectl get svc

eks-node-viewer

##Karpenter - 
##1. Setup Env for Karpeneter
export KARPENTER_VERSION=v0.23.0
echo "export KARPENTER_VERSION=${KARPENTER_VERSION}" >> ~/.bash_profile
TEMPOUT=$(mktemp)
curl -fsSL https://karpenter.sh/"${KARPENTER_VERSION}"/getting-started/getting-started-with-eksctl/cloudformation.yaml > $TEMPOUT \
&& aws cloudformation deploy \
  --stack-name Karpenter-${CLUSTER_NAME} \
  --template-file ${TEMPOUT} \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ClusterName=${CLUSTER_NAME}

  eksctl create iamidentitymapping \
  --username system:node:{{EC2PrivateDNSName}} \
  --cluster  ${CLUSTER_NAME} \
  --arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME} \
  --group system:bootstrappers \
  --group system:nodes

  kubectl describe configmap -n kube-system aws-auth

  eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

  eksctl utils associate-iam-oidc-provider --cluster dlp-eks-cluster --approve

eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME --name karpenter --namespace karpenter \
  --role-name "${CLUSTER_NAME}-karpenter" \
  --attach-policy-arn arn:aws:iam::$AWS_ACCOUNT_ID:policy/KarpenterControllerPolicy-$CLUSTER_NAME \
  --role-only \
  --approve

## 2. Install Karpeneter
export KARPENTER_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${CLUSTER_NAME}-karpenter"
export CLUSTER_ENDPOINT="$(aws eks describe-cluster --name ${CLUSTER_NAME} --query "cluster.endpoint" --output text)"
echo "export KARPENTER_IAM_ROLE_ARN=${KARPENTER_IAM_ROLE_ARN}" >> ~/.bash_profile
echo "export CLUSTER_ENDPOINT=${CLUSTER_ENDPOINT}" >> ~/.bash_profile
helm upgrade --install --namespace karpenter --create-namespace \
  karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version ${KARPENTER_VERSION}\
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=${KARPENTER_IAM_ROLE_ARN} \
  --set settings.aws.clusterName=${CLUSTER_NAME} \
  --set settings.aws.clusterEndpoint=${CLUSTER_ENDPOINT} \
  --set settings.aws.defaultInstanceProfile=KarpenterNodeInstanceProfile-${CLUSTER_NAME} \
  --set settings.aws.interruptionQueueName=${CLUSTER_NAME} \
  --set nodeSelector.intent=control-apps \
  --wait

kubectl get pods --namespace karpenter

kubectl get deployment -n karpenter

##3. Setup provisioner
cat <<EOF | kubectl apply -f -
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  labels:
    intent: apps
  requirements:
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot"]
    - key: karpenter.k8s.aws/instance-size
      operator: NotIn
      values: [nano, micro, small, medium, large]
  limits:
    resources:
      cpu: 1000
      memory: 1000Gi
  ttlSecondsAfterEmpty: 30
  ttlSecondsUntilExpired: 2592000
  providerRef:
    name: default
---
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: default
spec:
  subnetSelector:
    alpha.eksctl.io/cluster-name: ${CLUSTER_NAME}
  securityGroupSelector:
    alpha.eksctl.io/cluster-name: ${CLUSTER_NAME}
  tags:
    KarpenerProvisionerName: "default"
    NodeType: "karpenter-workshop"
    IntentLabel: "apps"
EOF

##4. Automatic provision
cat <<EOF > inflate.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      nodeSelector:
        intent: apps
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.2
          resources:
            requests:
              cpu: 1
              memory: 1.5Gi
EOF
kubectl apply -f inflate.yaml

##### EKS Troubleshooting - 
[02/23/23 10:33 AM] Liu, Peter: deploy.yaml
[02/23/23 10:42 AM] Liu, Peter: ubectl get secret -n ingress-nginx
[02/23/23 10:42 AM] Liu, Peter: kubectl get secret -n ingress-nginx
[02/23/23 10:51 AM] Liu, Peter: https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/
[02/23/23 11:20 AM] Liu, Peter: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
[02/23/23 11:34 AM] Liu, Peter: helm uninstall aws-load-balancer-controller \
    -n kube-system
[02/23/23 11:34 AM] Liu, Peter: eksctl delete iamserviceaccount \
    --cluster eksworkshop-eksctl \
    --name aws-load-balancer-controller \
    --namespace kube-system \
    --wait
[02/23/23 11:34 AM] Liu, Peter: aws iam delete-policy \
    --policy-arn arn:aws:iam:😳{ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
[02/23/23 11:35 AM] Liu, Peter: aws iam delete-policy \
    --policy-arn arn:aws:iam:😳{ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy
[02/23/23 11:36 AM] Liu, Peter: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
[02/23/23 12:07 PM] Liu, Peter: paste message here
[02/23/23 12:08 PM] ‹Gagan›: Events:
  Type     Reason                  Age                 From                Message
  ----     ------                  ----                ----                -------
  Normal   EnsuringLoadBalancer    50s (x5 over 2m5s)  service-controller  Ensuring load balancer
  Warning  SyncLoadBalancerFailed  50s (x5 over 2m5s)  service-controller  Error syncing load balancer: failed to ensure load balancer: error listing AWS instances: "NoCredentialProviders: no valid providers in chain. Deprecated.\n\tFor verbose messaging see aws.Config.CredentialsChainVerboseErrors"
[02/23/23 12:09 PM] Liu, Peter: aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
[02/23/23 12:10 PM] Liu, Peter: eksctl utils associate-iam-oidc-provider --cluster my-cluster --approve
[02/23/23 12:15 PM] Liu, Peter: kubectl patch svc <your service name> -p '{"metadata":{"finalizers":null}}'
[02/23/23 12:27 PM] Liu, Peter: kubectl drain --ignore-daemonsets <node name>
