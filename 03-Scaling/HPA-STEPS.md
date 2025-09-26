

# **Horizontal Pod Autoscaling (HPA) Setup and Testing Guide**

## **Introduction**

**Horizontal Pod Autoscaler (HPA)** is a Kubernetes feature that automatically adjusts the number of pod replicas in a deployment, replication controller, or replica set based on observed CPU, memory usage, or custom metrics. This guide explains how to set up HPA, configure resource requests/limits, and test the HPA using a load generator.

## **Prerequisites**

- A running Kubernetes cluster.
- `kubectl` installed and configured to interact with your cluster.

## **Step 1: Install the Metrics Server**

HPA relies on the **Metrics Server** to collect resource usage data like CPU and memory. The Metrics Server is not installed by default in most Kubernetes clusters.

To install the Metrics Server, run the following command:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

This will deploy the Metrics Server components to your Kubernetes cluster.

### **Verify Metrics Server Installation**

You can verify if the Metrics Server is working properly by running:

```bash
kubectl top nodes
kubectl top pods
```

If the command shows CPU and memory usage statistics, the Metrics Server is functioning correctly.

## **Step 2: Define Resource Requests and Limits**

To enable HPA, you need to define **resource requests and limits** for CPU and memory in the pod specification (usually within a Deployment YAML file). HPA uses these requests/limits to make scaling decisions.

Here is an example of a **Deployment** with CPU and memory requests/limits defined:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bankapp
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
      containers:
      - name: bankapp
        image: kuchalakantikris/bankapp:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: jdbc:mysql://mysql-service:3306/bankappdb?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true
        - name: SPRING_DATASOURCE_USERNAME
          value: root
        - name: SPRING_DATASOURCE_PASSWORD
          value: Test@123
        resources:
          requests:
            memory: "500Mi"
            cpu: "500m"
          limits:
            memory: "1000Mi"
            cpu: "1000m"
```

### **Apply the Deployment**

Once you have the resource requests and limits defined, apply the deployment:

```bash
kubectl apply -f bankapp-deployment.yaml
```

## **Step 3: Create the HPA Configuration**

After ensuring the deployment has proper resource requests and limits, create an HPA configuration to scale the application based on CPU utilization.

Here’s an example of an HPA configuration that scales the `bankapp` deployment when CPU utilization exceeds 50%:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: bankapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: bankapp
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # Scale when CPU utilization exceeds 50%
```

### **Apply the HPA Configuration**

Apply the HPA YAML:

```bash
kubectl apply -f bankapp-hpa.yaml
```

### **Verify HPA Creation**

To verify that the HPA has been created, run:

```bash
kubectl get hpa
```

The output should show the target deployment and the scaling range based on CPU utilization:

```
NAME         REFERENCE             TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
bankapp-hpa  Deployment/bankapp    10%/50%   1         10        1          1m
```

## **Step 4: Test HPA by Generating Load**

To test whether the HPA is working, you need to generate load on the application. You can do this by creating a **load generator pod** and running a loop that continuously sends HTTP requests to the service.

### **Step 4.1: Create a Load Generator Pod**

Run the following command to create a busybox pod to simulate the load:

```bash
kubectl run -i --tty load-generator --image=busybox -- /bin/sh
```

This will open an interactive shell inside the `load-generator` pod.

### **Step 4.2: Generate Continuous Load on the Application**

Inside the pod shell, run the following `while` loop to continuously send HTTP requests to your application:

```bash
while true; do wget -q -O- http://bankapp-service/api/transactions; done
```

This loop will continuously send HTTP requests to the `bankapp-service` at the `/api/transactions` endpoint, simulating heavy load on your application.

### **Step 4.3: Monitor the HPA and Scaling Behavior**

As the load increases, HPA will automatically scale the number of pods based on the CPU utilization.

You can monitor the HPA scaling actions by running:

```bash
kubectl get hpa
```

You should see the `REPLICAS` field increase as the load grows and the CPU utilization exceeds the threshold.

You can also check the number of running pods with:

```bash
kubectl get pods -l app=bankapp
```

### **Step 4.4: Stop the Load Generation**

Once you’re done testing, you can stop the load generation by pressing `Ctrl + C` inside the load generator pod, or you can simply exit the pod shell by typing:

```bash
exit
```

After some time, the number of pods should decrease as the load subsides and CPU usage drops below the threshold.


