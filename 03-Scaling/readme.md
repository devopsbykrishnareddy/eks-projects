## **Setup EKS Cluster**
Create VM & add the root access keys & secret accesskeys of root using aws cli

# **Install AWS CLI & Add credentails**
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws configure

#Install Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update && sudo apt-get install terraform -y

terraform -version

## **navigate to EKS terraform code**
# terraform init
# terraform validate
# terraform apply --auto-approve

# Install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
 
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version –client

# **Kubeconfig**

aws eks --region ap-south-1 update-kubeconfig --name devopsbykrishna-cluster

## **Deploy the application**

kubectl apply -f ds.yml
it will deploy the wo pods #one for mysqldb, apppod
it will create two services mysqlservice and appservice

now application will be running using Service type as load balancer

## **to perform Horizontal sacing**
verify HPA-STEPS.md documents in this repository, will have step by step guide to configuring horizontal scaling


## **to perform vertical sacling**
verify VPA-STEPS.md documents in this repository, will have step by step guide to configure vertical scaling