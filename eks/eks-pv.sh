### Allow your EKS cluster to create a PV
# Refer https://aws.amazon.com/premiumsupport/knowledge-center/eks-persistent-storage/

#Step 1: Create below IAM Policy and name as AmazonEKS_EBS_CSI_Driver_Policy


{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications",
        "ec2:DetachVolume",
        "ec2:ModifyVolume"
      ],
      "Resource": "*"
    }
  ]
}

#Step 2: Describe your cluster OIDC provider
aws eks describe-cluster --name <your_cluster_name> --query "cluster.identity.oidc.issuer" --output text

aws eks describe-cluster --name dlp-eks-cluster --query "cluster.identity.oidc.issuer" --output text
#Step 3: Create a trust policy file.
cat <<EOF > trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.YOUR_AWS_REGION.amazonaws.com/id/<XXXXXXXXXX45D83924220DC4815XXXXX>:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
EOF

## In above replace YOUR_AWS_ACCOUNT_ID with your account ID. Replace YOUR_AWS_REGION with your AWS Region. Replace XXXXXXXXXX45D83924220DC4815XXXXX with the value returned in step 3.

# Step 3: Create an IAM Role named - AmazonEKS_EBS_CSI_DriverRole
aws iam create-role \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --assume-role-policy-document file://"trust-policy.json"

# Step 4: Attach IAM Policy to the Role
aws iam attach-role-policy \
--policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AmazonEKS_EBS_CSI_Driver_Policy \
--role-name AmazonEKS_EBS_CSI_DriverRole

# Step 5: Deploy EBS CSI driver 
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=master"

# Step:6 Annotate Annotate the ebs-csi-controller-sa Kubernetes service account with the Amazon Resource Name (ARN) of the IAM role that you created earlier:
kubectl annotate serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/AmazonEKS_EBS_CSI_DriverRole
# Replace YOUR_AWS_ACCOUNT_ID with your account ID.

kubectl annotate serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::353013733335:role/eksctl-dlp-eks-cluster-cluster-ServiceRole-32NMNS8T89O

kubectl annotate serviceaccount ebs-csi-controller-sa \
  -n kube-system \
  eks.amazonaws.com/role-arn=arn:aws:iam::353013733335:role/AmazonEKS_EBS_CSI_DriverRole

eksctl get addon --name aws-ebs-csi-driver --cluster dlp-eks-cluster

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster dlp-eks-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole

eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster dlp-eks-cluster \
  --region ap-south-1 \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name arn:aws:iam::353013733335:role/eksctl-dlp-eks-cluster-cluster-ServiceRole-32NMNS8T89O

  eksctl create addon --name aws-ebs-csi-driver --cluster dlp-eks-cluster --service-account-role-arn arn:aws:iam::353013733335:role/AmazonEKS_EBS_CSI_DriverRole --force

aws eks update-kubeconfig --region ap-south-1 --name dlp-eks-cluster
aws eks describe-addon-versions --addon-name aws-ebs-csi-driver

eksctl create addon --name aws-ebs-csi-driver --cluster dlp-eks-cluster --region ap-south-1 --service-account-role-arn arn:aws:iam::353013733335:role/eksctl-dlp-eks-cluster-cluster-ServiceRole-32NMNS8T89O --force
eksctl get addon --name aws-ebs-csi-driver --cluster dlp-eks-cluster --region ap-south-1 
eksctl delete addon --cluster dlp-eks-cluster --region ap-south-1 --name aws-ebs-csi-driver --preserve

aws eks delete-addon --cluster-name dlp-eks-cluster --addon-name aws-ebs-csi-driver --preserve

aws iam get-role --role-name eksctl-dlp-eks-cluster-cluster-ServiceRole-32NMNS8T89O --query Role.AssumeRolePolicyDocument

aws iam list-attached-role-policies --role-name eksctl-dlp-eks-cluster-cluster-ServiceRole-32NMNS8T89O --query AttachedPolicies[].PolicyArn --output text

kubectl describe serviceaccount ebs-csi-controller-sa -n default
