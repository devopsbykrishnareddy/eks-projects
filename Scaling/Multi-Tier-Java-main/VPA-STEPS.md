

# **Vertical Pod Autoscaler (VPA) Setup and Testing Guide**

## **Introduction**

**Vertical Pod Autoscaler (VPA)** automatically adjusts the CPU and memory requests for containers in a Kubernetes pod based on actual usage. This ensures efficient resource utilization and eliminates the need to over-provision resources. Unlike Horizontal Pod Autoscaler (HPA), which scales the number of pods, VPA optimizes the resource allocation for individual pods.

In this guide, you will learn how to install the VPA components, configure resource requests for the pods, create the VPA configuration, and test VPA.

## **Step 1: Install VPA Components**

To install the VPA components, follow the steps below:

### **Step 1.1: Clone the VPA Repository**

You will need to clone the Kubernetes autoscaler repository to access the VPA installation scripts:

```bash
git clone https://github.com/kubernetes/autoscaler.git
```

### **Step 1.2: Run the VPA Setup Script**

Navigate to the `vertical-pod-autoscaler` directory and run the setup script to install the necessary VPA components:

```bash
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-up.sh
```

This will set up the VPA controller and other necessary components in your Kubernetes cluster.

### **Verify VPA Installation**

Once the VPA components are installed, you can check the installed VPA components by running:

```bash
kubectl get pods -n kube-system | grep vpa
```

You should see three VPA components running:

- `vpa-recommender`
- `vpa-updater`
- `vpa-admission-controller`

## **Step 2: Define Resource Requests in Deployment**

To use VPA, you need to ensure that the **requests** for CPU and memory are defined in your pod specification. Here’s an example of the **bankapp** deployment with resource requests:

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

Run the following command to apply the deployment:

```bash
kubectl apply -f bankapp-deployment.yaml
```

## **Step 3: Create the VPA Configuration**

Now, create a **Vertical Pod Autoscaler (VPA)** resource that will monitor and adjust the resource requests for the `bankapp` deployment.

### **Example VPA YAML:**

Here’s an example of a VPA configuration in `Auto` mode. In this mode, VPA automatically updates the CPU and memory requests based on actual usage:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: bankapp-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: bankapp
  updatePolicy:
    updateMode: "Auto"  # Automatically updates CPU and memory requests based on usage
```

### **Apply the VPA Configuration**

Save the above YAML as `bankapp-vpa.yaml` and apply it:

```bash
kubectl apply -f bankapp-vpa.yaml
```

### **Verify VPA Configuration**

To verify the VPA configuration is applied correctly, run:

```bash
kubectl get vpa
```

This should display your newly created VPA for the `bankapp` deployment.

## **Step 4: Test VPA**

To test the VPA and observe how it adjusts the resource requests dynamically based on real usage, follow these steps.

### **Step 4.1: Generate Load on the Application**

Use the same method as for HPA to generate load on your **bankapp** deployment. You can use a **busybox** pod to create continuous load:

1. Create a **load generator pod**:

   ```bash
   kubectl run -i --tty load-generator --image=busybox -- /bin/sh
   ```

2. Inside the pod shell, run the following loop to continuously send HTTP requests to the service:

   ```bash
   while true; do wget -q -O- http://bankapp-service/api/transactions; done
   ```

This loop will keep sending HTTP requests, simulating load on the application.

### **Step 4.2: Monitor the VPA Recommendations**

You can monitor the VPA’s recommendations and adjustments to the resource requests by describing the VPA:

```bash
kubectl describe vpa bankapp-vpa
```

You should see recommended resource requests based on the observed CPU and memory usage. The output will look something like this:

```
Recommendations:
  Container Recommendations:
    Container Name: bankapp
    Lower Bound:
      Cpu:     300m
      Memory:  400Mi
    Target:
      Cpu:     600m
      Memory:  700Mi
    Upper Bound:
      Cpu:     1000m
      Memory:  1Gi
```

This shows the range of CPU and memory recommendations based on the actual load on the application.

### **Step 4.3: Check the Adjusted Resources in the Pod**

To verify that the VPA has adjusted the resource requests in the running pods, you can describe the pod and check the resource section:

```bash
kubectl get pod <pod-name> -o yaml | grep -A5 resources
```

This will display the current CPU and memory requests that have been dynamically adjusted by VPA.

### **Step 4.4: Stop the Load Generation**

Once you have tested the VPA, stop the load generation by pressing `Ctrl + C` inside the `load-generator` pod or exit the pod shell:

```bash
exit
```

## **Step 5: Clean Up (Optional)**

If you no longer need the VPA or the test pods, you can clean them up by deleting the VPA and load generator pod:

```bash
kubectl delete vpa bankapp-vpa
kubectl delete pod load-generator
```

---

## **Conclusion**

In this guide, we covered how to set up **Vertical Pod Autoscaler (VPA)** in Kubernetes. We installed the VPA components, configured resource requests in the deployment, created a VPA resource, and tested it by generating load on the application. VPA will now dynamically adjust the resource requests for your application based on real-time usage, ensuring optimal resource utilization.

