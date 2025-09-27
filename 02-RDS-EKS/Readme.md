## **Create EKS Cluster & Use RDS as Database**

Create VM & add the root access keys & secret accesskeys of root using aws cli

# Install AWS CLI & Add credentails
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws configure

### **Install Terraform**
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl

curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update && sudo apt-get install terraform -y

terraform -version

Clone below Repo & go inside it & run terraform init and after wards terraform apply –auto-approve

https://github.com/devopsbykrishnareddy/EKS-Mysql-Project.git


# **Kubeconfig**

aws eks --region ap-south-1 update-kubeconfig --name devopsbykrishna-cluster

# **Kubectl**
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
 
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

kubectl version --client

## **Install RDS-Mysql from AWS portal**

### ***Quick prerequisites***

AWS account + an IAM user with RDS + VPC + EC2 (for security group) permissions.

A VPC with at least two private subnets (recommended for production).

Know whether you want public access (for testing) or private-only (recommended for production).

### *** Step-by-step (AWS Console)***

Sign in & pick a Region

Sign in to the AWS Management Console and choose the AWS Region where you want the DB.

Open RDS

Services → RDS.

Start creating the database

In the left menu choose Databases → Create database.

Choose creation method

Select Standard create (gives full control). (You can use Easy create for fast defaults.)

Choose engine

Under Engine options pick MySQL and select the desired MySQL version (e.g., 8.0). Pick a version that matches your app compatibility.

Choose a template

Options: Production, Dev/Test, or Free tier.

For experiments pick  Dev/Test. For real usage choose Production.

Configure DB instance

DB instance identifier — a friendly name (e.g., myapp-db).

Credentials - use self managed
Master username — e.g., root .

Master password — set a strong password (or use Secrets Manager later).

Instance class and availability

DB instance class — pick a size (e.g., db.t3.micro for free tier/dev; production often uses db.t3.medium or larger).

Multi-AZ deployment — enable for high availability (recommended for production).

### ***Storage***

Storage type — General Purpose SSD (gp3) is typical; 

Allocated storage — set GBs (e.g., 20 GB). Optionally Enable storage autoscaling.

### ***Connectivity***
Dont connect to Ec2 compute resource

Virtual private cloud (VPC) — We are supposed create this RDS DB inside the VPC same as where EKS cluster is running.

Subnet group — choose create DB subnet group

Public accessibility — No for production (keeps DB private). Set Yes only for test or if you intentionally want public access.

VPC security groups — select default and  exisiting EKS SG which is associated to nodes

use all default options

create RDS

# **MAINFESTFILE**

---
apiVersion: v1
kind: Secret
metadata:
  name: rds-mysql-secret
  namespace: webapps
type: Opaque
stringData:
  SPRING_DATASOURCE_USERNAME: root
  SPRING_DATASOURCE_PASSWORD: Password#123
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: rds-mysql-config
  namespace: webapps
data:
  SPRING_DATASOURCE_URL: jdbc:mysql://rds-mysql:3306/bankappdb?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
---
apiVersion: v1
kind: Service
metadata:
  name: rds-mysql
  namespace: webapps
spec:
  type: ExternalName
  externalName: database-1.ctmywc4am62c.ap-south-1.rds.amazonaws.com
  ports:
    - port: 3306
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bankapp
  namespace: webapps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bankapp
  template:
    metadata:
      labels:
        app: bankapp
    spec:
      initContainers:
        - name: init-create-db
          image: mysql:8
          command:
            - sh
            - -c
            - mysql -h rds-mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS bankappdb;"
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: rds-mysql-secret
                  key: SPRING_DATASOURCE_PASSWORD
      containers:
        - name: bankapp
          image: kuchalakantikris/bankapp
          resources:
            requests:
              memory: 256Mi
              cpu: 250m
            limits:
              memory: 512Mi
              cpu: 500m
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_URL
              valueFrom:
                configMapKeyRef:
                  name: rds-mysql-config
                  key: SPRING_DATASOURCE_URL
            - name: SPRING_DATASOURCE_USERNAME
              valueFrom:
                secretKeyRef:
                  name: rds-mysql-secret
                  key: SPRING_DATASOURCE_USERNAME
            - name: SPRING_DATASOURCE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: rds-mysql-secret
                  key: SPRING_DATASOURCE_PASSWORD
          livenessProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 60
            timeoutSeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 60
            timeoutSeconds: 5
            periodSeconds: 10
            failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: bankapp-service
  namespace: webapps
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: bankapp





## **APPLY MAINFEST FILE**

Create namespace
kubectl create ns webapps

kubectl apply -f mainfest.yml -n webapps

kubectl get all -n webapps

kubectl describe pod <podname> -n webapps

kubectl logs  <podname> -n webapps

browse appliction use load balancer external ip

submit the data from application 

verify the data is available on mysql

use below yaml to test rds using mysql-client
## **Test-Pod**

apiVersion: v1
kind: Pod
metadata:
  name: mysql-client
spec:
  containers:
  - name: mysql
    image: mysql:8
    command: ["sleep"]
    args: ["3600"]

kubectl apply -f test-pod.yaml -n webapps

### **to connect rds**
kubectl exec -it mysql-client -n webapps -- bash 

bash# mysql -h <dbendpoint> -u root -p
password: <enter the pwd>

mysql> show databases;
you can see bankapp db is present

mysql> use bankappdb;

mysql> show tables;

mysql> select * from account;









