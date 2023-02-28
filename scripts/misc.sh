### Remove all images ###
docker rmi $(docker images -q)

sh ops-console-deploy.sh 

docker-compose build --no-cache operational-console
docker-compose up -d operational-console

### Deploy Operational-console ###
ssh integ
cd /data/
cd operational-console
git pull 

##SCP
=====
scp -i /Users/gagan.singla/devtools/pem/dlp-integration-server.pem -r /Users/gagan.singla/Documents/Work/SecurityIssues/mde/XMDEClientAnalyzer/ ec2-user@43.205.254.66:/tmp/mde

scp -i <keyfile> -r <path1/> <ec2-user@ip:path2>

scp -i  /Users/gagan.singla/devtools/pem/dlp-integration-server.pem -r /Users/gagan.singla/Documents/Work/SecurityIssues/ ec2-user@<IP>:/tmp/

cd /Users/gagan.singla/Documents/Work/SecurityIssues
cd /Users/gagan.singla/devtools/pem/ 

###SSH file
======
cd ~/.ssh
vi config

### 
#### CDC versions
cdc-message-consumer_CI-0.0.2
cdc-message-consumer_CI-0.0.5
cdc-node-backend_CI-0.0.25
cdc-node-frontend_CI-0.0.15

### Check OS version
Type any one of the following command to find os name and version in Linux:
cat /etc/os-release
lsb_release -a
hostnamectl
###Type the following command to find Linux kernel version:
uname -r

### PATCHING
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/al2-live-patching.html




### MDE Ticket
https://support.accenture.com/support_portal?id=acn_service_catalog_dp&sys_id=c9856641139a6600380ddbf18144b05f
App - Microsoft Defender Server Endpoints
Type - App SW reporting
Summary - MDE | Assign the ticket to APPSUPPORT-CFTOOLS-MDEOps

### MDE Client Analyzer lpogs
1. Download the zip file from below path

https://ts.accenture.com/sites/Information_Security2/TechnologyAndOperations/EDM/Shared%20Documents/Forms/AllItems.aspx?id=%2Fsites%2FInformation%5FSecurity2%2FTechnologyAndOperations%2FEDM%2FShared%20Documents%2FPublic%20Repo%2FLinux%20Installation%20Materials%2FXMDEClientAnalyzer%2Ezip&parent=%2Fsites%2FInformation%5FSecurity2%2FTechnologyAndOperations%2FEDM%2FShared%20Documents%2FPublic%20Repo%2FLinux%20Installation%20Materials

2. scp the files to Server

scp -i /Users/gagan.singla/devtools/pem/dlp-integration-server.pem -r /Users/gagan.singla/Documents/Work/SecurityIssues/mde/XMDEClientAnalyzer/ ec2-user@43.205.254.66:/tmp/mde

### Server Timezone changes
sudo yum install chrony
cat /etc/chrony.conf
--> add the line after any other server or pool statements that are already present in the file, and save your changes.
server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4 /bin/systemctl restart chronyd.service ### Verify that chrony is using the 169.254.169.123 IP address to synchronize the time. 
chronyc sources -v
### Below line indicates that
###  ^* 169.254.169.123               3   4   377     7  +1393ns[  +28us] +/-  118us
chronyc tracking
timedatectl
timedatectl list-timezones
sudo timedatectl set-timezone Asia/Kolkata



### Expand / Extend an EBS Volume
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/recognize-expanded-volume-linux.html df -hT
sudo lsblk 
##<<if [Ext4 file system] Use the resize2fs command and specify the name of the file system that you noted in the previous step.>>
sudo resize2fs /dev/nvme1n1
##<<if [XFS file system] Use the xfs_growfs command and specify the mount point of the file system that you noted in the previous step.>> 
sudo growpart /dev/nvme0n1 1
sudo xfs_growfs -d / 

### Push a Docker image to DLP ECR
##===============================
aws ecr get-login-password --region ap-south-1 | docker login -u AWS --password-stdin 353013733335.dkr.ecr.ap-south-1.amazonaws.com 
#docker tag ${APP_NAME}:latest 353013733335.dkr.ecr.ap-south-1.amazonaws.com/dlp-ecr-repository:${APP_NAME}_${IMAGE_TAG} 
#docker push 353013733335.dkr.ecr.ap-south-1.amazonaws.com/dlp-ecr-repository:${APP_NAME}_${IMAGE_TAG}

docker tag cdc-node-frontend:v5 353013733335.dkr.ecr.ap-south-1.amazonaws.com/dlp-ecr-repository:cdc-node-frontend_v5 
docker push 353013733335.dkr.ecr.ap-south-1.amazonaws.com/dlp-ecr-repository:cdc-node-frontend_v5

##### ElasticSearch Kibana ELK Secrets Get Password ####
kubectl get secrets | grep elastic
kubectl get secret elasticsearch-cluster-es-elastic-user -o yaml
echo -n 'NkNpSzNtczhJNUQ4UEsxejcyTVcwZk8y' | base64 --decode

### install SSM agent
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm

##check SSM agent status
sudo systemctl status amazon-ssm-agent

##start ssm agent
sudo systemctl start amazon-ssm-agent

