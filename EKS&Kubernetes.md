key info for this project: 
https://calculator.aws/#/addService  # for cost calculation


Written with my own hands, formatted by AI for speed


```

VPC	Isolated network for all resources
Subnets (public + private)	Public for ALB / NAT, private for EC2 or EKS
Security Groups	Access control — ALB → EC2 → RDS
VPC Endpoints	Internal AWS access (S3, CloudWatch, etc.) without Internet
EKS (optional)	If project goal = WordPress on Kubernetes
RDS	Managed MySQL database (instead of S3 for DB)
S3	State + Media/backup storage
IAM roles/policies	Access S3, CloudWatch, etc. securely
The architecture of the end project
              +-----------------------+
              |     Route 53 (DNS)    |
              +-----------+-----------+
                          |
                   +------+------+
                   |  ALB (Public) |
                   +------+------+
                          |
                 +--------v--------+
                 | EC2 / EKS Nodes |
                 | WordPress Pods  |
                 +--------+--------+
                          |
                +---------v---------+
                |  RDS (MySQL DB)   |
                +-------------------+

VPC (private + public subnets)
|
+-- VPC Endpoints (S3, Logs, SSM, ECR)
|
+-- S3 (state + media)
|
+-- SG (allow ALB → EC2, EC2 → RDS)

```


1. Kubernetes Concepts

Table of Contents
- Architecture
- DevOps
- Microservices
- Docker
- Kubernetes Intro
- EKS commands and kubectl
- Defining resources (Namespaces, Contexts)
- Kubernetes PODs
- Services and Networking
- ReplicaSets
- Deployments
- Bonus for later

Architecture

1. AWS services Integration with EKS
Fundamentals:
Imperative:
	kubectl,             ->  Pod, ReplicaSet, Deployment, Service
Declarative:
	YALM&Kubectl ->  Pod, ReplicaSet, Deployment, Service

Because Kubernetes resources are declarative and self-healing:
A Pod will wait and retry until its referenced ConfigMap or Secret exists.
A Service can exist before the Pods it selects — it just won’t have endpoints yet.
A Deployment can create its ReplicaSet even before the Service exists — they’re loosely coupled via labels.
```
Type	                                     Recommended order	Why  # the order of creation of resources
Namespaces	                                 First	Everything else lives inside them
RBAC (Roles, RoleBindings, ServiceAccounts)	 Second	Pods and controllers might need permissions
ConfigMaps / Secrets	                     Third	Pods reference them
Services / Deployments / StatefulSets	     Fourth	Core workloads
Ingress / NetworkPolicy	                      Last	Depend on running Services and Pods
```
You can apply them all at once — Kubernetes will eventually reconcile the correct state — but applying them in this logical order avoids transient “NotFound” warnings.


CLI's:  AWS CLI - control multiple AWS services though command line and automate though scripts. Manages the cluster
kubectl - manages the cluster and objects
eksctl - manages the clusters and objects / create and delete clusters on AWS EKS, create Autoscale and delete node groups, create Fargate profiles.

Moving worker nodes to private subnets is a best practice and Load Balancer to public subnets !!!! WHY!!!!

aws ec2 describe-vpcs     # fetches VPCs under aws confidure account

EKS Cluster made out of ( In EKS the following it is managed by AWS):
EKS Control Plane
	It is the Master Node in regular Kubernetes Achitecure - It hosts etcd, kube api server, kubectl (kube controller)
	EKS Control Plane - Eks runs a single tenant (user) K8s control plane for each cluster and control plane infrastructure
	This control plane consists of at least two API server nodes and three etcd nodes that run across three availability zone within a region - You are not sharing etcd or API server with other AWS users on AWS infrastructure.
	Each EKS cluster has its own isolated control plane even though you do no manage the servers directly ( etcs, controller manager, scheduler kube-apiserver (all kubectl/eksctl calls go there))
	Eks auto detects and replaces unhealty control plane instances, restarting them across AZ-s within a region as needed.
	Three etcd nodes across three Availability Zones”
	etcd is critical → it stores all Kubernetes cluster state.
	AWS deploys 3 etcd nodes (minimum), one in each Availability Zone (AZ) in the region.
	This forms a quorum (majority voting system):
	Even if one AZ goes down, 2 etcd nodes remain → cluster keeps running. Ensures durability and fault tolerance.

	
Worker Nodes/Node Groups
	Group of EC2 instances that run the apps - deploy our k8 apps
	AMI-s are specifiically designed for K8 AWS
	EKS worker nodes running in our AWS account and connect to our cluster's control plane via the cluster API server endpoint - This cluster server API endpoint should be exposed to the internet and can be used to comunicate with our VPC
	A node group is one or mode EC2 instances that are deployed   in an EC2 Autoscalling group
	Worker machines in k8 = nodes (ec2 instances)
	All instances ina a node group must have the same: Instance Type, AMI, KES worker node IAM role


Fargate Profiles/Serverless - Fargate runs only on PRIVATE subnets
	CPU,RAM is abstracted away and is autoscalable - you pay what you use
    Each pod running on Fargate has its own isolation boundary - kernel, CPU, Memory, elastic network with another pod

On demand, rightsized compute capacity for containers
    AWS specially build Fargate controllers that recognizes the pods belonging to fargate and chedules them on Fargate profiles
    Does not share underlying resources ( CPI, mem, etc)


VPC
	Security comes from the design of the VPC - You can delpoy to private or public subnets
	Fargate runs only on PRIVATE subnets!
	If you deploy apps to private subnets in worker nodes (ec2 or Fargate) we neet to setup comunication with the control plane with:
	A **NAT Gateway** (in a public subnet) → gives them outbound internet.
    Or **EKS Private Endpoint** (VPC endpoint for the control plane).
    EKS uses AWS VPC network policies to restrict traffic between control planet components to within a single cluster 
    Control plane components for a EKS cluster cannot view or receive communication from other clusters or other AWS accounts except as authorized with Kubernetes RBAC policies
    This kind of configuration is secure and highly available - EKS is reliable and very good for production workloads



2. DevOps
Pipeline for apps and also for Kubernetes manifest:

If you make any change to Kubernetes manifest and check that core it will be deployed to you K8s cluster. Same for applications, they will get build a new Docker image and deploy it to the K8s cluster. 

3. Microservices

Service discovery
Distribuited Tracing 
Canary Deployments
```
NameSpaces:

The `dev` and `prod` namespaces exist in the **same cluster** but manage **different sets of resources**.  
> Resources in one namespace are not visible in the other.

├── Namespace: dev
│ ├── Deployment: web-app
│ ├── Pod: web-app-123
│ ├── Service: web-svc
│ └── ConfigMap: app-config
│
└── Namespace: prod
├── Deployment: web-app
├── Pod: web-app-456
├── Service: web-svc
└── ConfigMap: app-config

Clusters are **completely independent** of one another.  
> Even if namespaces share the same name (e.g. `dev`), they belong to **different clusters** and cannot access each other's resources.

├── Namespace: dev
│ ├── Deployment: api-server
│ └── Service: api-svc
│
└── Namespace: staging
├── Deployment: web-ui
└── Service: ui-svc
```

OIDC - Open ID connect

Humans have IAM accounts

Service accounts lets resources (not humans ) comunicate like pods to authenticate to the API or authenticate to cloud services via OIDC/IRSA in AWS / Service Accounts = identities for workloads (pods, controllers, jobs), not for humans.

- Open ID Connect (OIDC) allows Pods to authenticate to other services (s3, EBS, DynamoDb) without storing AWS credentials inside the pod and uses the IAM Role:
This means that pods do not need an AWS configure account to reach services
- Each Pod uses a Service Account. We link that Service Account to an IAM Role.
AWS trusts the identity coming from EKS, so the Pod gets temporary access without secrets
- storing AWS keys inside containers is insecure 

```
Pod ----> uses ServiceAccount token
   \
    \  (federated identity trust via OIDC)
     \
      IAM Role (IRSA)
       \
        AWS Service (S3, EBS, DynamoDB, etc.)

```

Both from above must respect RBAC rules to decide what they can do

- Pod runs in EKS with a **Service Account**.
    
- EKS issues a **JWT** for that SA (signed by EKS OIDC provider).
    
- Pod presents JWT to AWS STS (IAM Security Token Service).
    
- AWS IAM checks:
    
    - Is this JWT signed by a trusted OIDC provider (your EKS cluster)?
        
    - Does it match the IAM role trust policy?
        
- If yes → IAM gives the pod **temporary AWS credentials**.
    
- Now the pod can access AWS resources securely.

OIDC = a **way to log in** (authentication) that apps and systems can use to trust each other without storing passwords or static keys.

- OAuth2 → “Can this app act on your behalf?” (authorization).
    
- OIDC → “Who is this user/app really?” (authentication)


In AWS EKS:

- Your cluster acts (is) as the an **OIDC Identity Provider**.
	-The **EKS control plane** has an **OIDC endpoint** (your cluster’s OIDC provider).
    
	-When a pod starts, Kubernetes mounts a token into it at:
    
    `/var/run/secrets/kubernetes.io/serviceaccount/token`
    
- That token is a **JWT signed by the cluster’s OIDC provider**.
    
- Pods get OIDC **JWT tokens** tied to their Kubernetes Service Accounts.
    
- AWS IAM is configured to **trust** that OIDC provider.
    
- Result: Pods can use their JWTs to assume IAM roles → access AWS resources.# In AWS EKS

- Pods get OIDC **JWT tokens** tied to their Kubernetes Service Accounts.
    
- AWS IAM is configured to **trust** that OIDC provider.
    
- Result: Pods can use their JWTs to assume IAM roles → access AWS resources.

- The **EKS control plane** has an **OIDC endpoint** (your cluster’s OIDC provider).    


How does the token know it belongs to the Service Account?

It’s inside the **JWT payload**

Example decoded JWT from a pod:

{
  "iss": "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE1234",
  "sub": "system:serviceaccount:default:s3-writer",
  "kubernetes.io/serviceaccount/namespace": "default",
  "kubernetes.io/serviceaccount/service-account.name": "s3-writer",
  "exp": 1738927347,
  "aud": "sts.amazonaws.com"
}


Look at the key parts:

- `"sub": "system:serviceaccount:default:s3-writer"` → this says: **token belongs to Service Account `s3-writer` in namespace `default`**.
    
- `"iss"` → who issued it (your EKS OIDC provider).
    
- `"aud"` → who this token is for (in IRSA it’s AWS STS).
    

So the binding happens because the **JWT itself encodes the Service Account name + namespace**.

JSON Web Token

1. The JWT is **digitally signed** by the OIDC provider (your cluster).
    
2. AWS IAM knows the provider’s **public key** (from when you did `eksctl utils associate-iam-oidc-provider`).
    
3. IAM verifies the signature → proves the JWT really came from your cluster.
    
4. IAM checks the **claims** (like `sub`) against the IAM Role trust policy.
    
    - Example condition in trust policy:
        
        "Condition": {
  "StringEquals": {
    "oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE:sub": "system:serviceaccount:default:s3-writer"
  }
}


That line literally says: _“Only accept tokens tied to Service Account `s3-writer` in namespace `default`.”_
    
- Pods get tokens automatically mounted.
    
- The JWT explicitly contains the **Service Account identity** (`sub` claim).
    
- The OIDC provider signs it.
    
- AWS IAM trusts the signature and matches the `sub` to the Service Account you allowed in the trust policy.
    

The tokens are **tied to Service Accounts because the JWT contains the SA name + namespace in its claims, and the signature ensures it can’t be faked.**


So, EKS control plane has an OIDC provider that has and endpoint though which a JWT

This path is located in the pod where each JWT ( Json Web Token)
kubectl exec -it mypod -- sh
ls /var/run/secrets/kubernetes.io/serviceaccount/token
you may see : ca.crt  namespace  token

**For example this command :**
**eksctl utils associate-iam-oidc-provider  # does not create pod tokens, instead it registers cluster OIDC endpoint in IAM so later when pods are created and present tokens, IAM knows how to validate them - This is a one setup of trust**
**When is the OIDC JWT actually created?**
**When a Pod is created, Kubernetes assigns it a Service Account ( default or custom )** # Never create a pod by itself - must create a daployment or whatever resource you want
**The kubelet on the node automatically requests a token for that Service Account from the EKS control plane**
**The token will be signed by the EKS OIDC provider -> It contains: service account name, namespace, audience, expiry**
**The token is mounted inside the pod at : ls /var/run/secrets/kubernetes.io/serviceaccount/token**

**Verify service accounts in cluster : kubectl get sa -n default**


**https://www.youtube.com/watch?v=4NnJf9SUf0Y**


Docker

Docker solves the problems 
Installation and configuration - LIbraries and dependencies, operating sistems, hardware infra - all of this becomes reproducable with docker images. Inconsistencies across envs. In Docker you can leverage all of them at once. Developer environments are provisioned imediately by spinning up necessary requirements.txt

Virtual machines achitecture using Docker :

Hardware infra -> Hypervisor -> Multimple Docker containers -> Operating Sys -> Llibraries, Dependencies, webservers, databases, envs etc

Physical machines architecture using Docker:
Hardware -> Operating Sys -> Docker - > Containers

Advantages: Flexible, Lightweight, Portable, Loosely coupled (self sufficient, upgrade one without affecting others),Scalable (more repicas accross a datacenter), secure (aggresive constraints)

Achitecture - Docker Terminology

Docker Daemon:
	Inside DockerHost we install Docker Daemon (dockerd) -> listens for Docker PI requests and manages Docker Objects such as images, containers, networks, volumes

Docker Client:
	Docker client can be present on either Docker Host or any other machine
	The Docker client (docker) is the primary way that many Docker users interact with Docker - When docker run, the client sends these commands to dockerd (docker Daemon) which executes
	Docker commands use Docker API
	Docker client can comunicate with more that one Daemon

Docker Images:
	An image is a read-only template with instructions for creating a Docker image
	Docker images can be based on another image with additional customization (you can add to other images and make it your own custom)
	We can connect a container to one or more networks, attach storage to it. 
	When a container is removed, any changes to its state that are not stored will dissapear



Docker host -> Docker Daemon 
If you want to pull and image -> we use Docker client (docker pull nginxdemo/hello) -> then Docker client comunicates with Docker Daemon on the Docker Host -> Then Daemon goes to Docker registry -> downloads to Docker images -> when docker run -p 80:80 -d nginxdemos/hello it runs the image in the container -> Run the image and test it -> then you can push it to the registry

Docker registry is a public image registry where you find images
You can push back to a Docker registry ( some are with payment )


Running docker images - from dockerhub

docker version
docker login -u plasticmemory
docker info | grep Username # to see which user you are logged
cat ~/.docker/config.json  # to get the json login token
docker pull /repository/imagename:tagnameMandatoryVersion0.0.0.0Release
docker run --name containername -p 80:8080 -d imagename:tagMandatoyAgain

If port conflicts exist then : sudo lsof -i :80  # or insert the port number that is in conflict to see what is running on the sys outside the docker or other tools that you are trying to use
docker run --name appcontainername -p 80:8080 -d "stacksimplify/dockerintro-springboot-helloworld-rest-api:1.0.0-RELEASE" 
docker ps -a -q # to list container ID only 
docker ps -q  # to list only running containers and only ID

docker logs  # this lists whatever has been executed in the container including the endpoint
Executing inside the container:
	docker exec -it 933d0f72e445 sh  # to access the shell. It does not have bash installed ( image has alpine linux very slim )
	cat /etc/os-release # to see which operating sys
	du -sh /  # to see total used container memory
	du -h -d1 / # total and folders only on level 1 of depth
	ps -ef # list running processes in the container  -e system wide processes, -f full format ( ppID, user, command path)
	ping 8.8.8.8  # to see network connectivity


curl http://localhost:8081/hello; echo # from outside the container
docker inspect containerid
docker inspect -f '{{json .Config.ExposedPorts}}' containername
docker inspect container name | grep IPAddress
docker ps -a --size # check how much the containers are using
docker system df # check docker usage
docker system prune # WARNING this deletes unused containers
docker ps -a --size # see each container how much mem is using
docker top containername

docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' containerID  # gets you the IP from nerworks

Building and pushing docker images - to dockerhub

docker login -u username # be shure to be logged
create folder for project or navigate where needed
create Dockerfile with everything that will be moved into the image
docker build -t username/imagename:v1  # or whatever tag you need
docker run -t --name choosecontainername -p 81:80 -d username/imagename:v1
Let's say you make modifications to the image and want a v2 and then a release version to upload to dockerhub:
docker tag imagenameV1 imagenameV2-release
both have same ID and changes are tracked similar to how github does
all versions will be uploaded to dockerhub
docker push plasticmemory/nginx-customimage:v2-release

Kubernetes Into

Kubernetes is portable, extensible, opensource platform for managing containerized workloads

Features:
Service discovery and load balancing
Storage orchestration
Automated rollouts and rollbacks
Automatic bin packing
Self-healing
Secret and config management
```
Components:

│
├── Control Plane (Managed by AWS)
│   ├── API Server                  ← Entry point for kubectl & system components
│   ├── etcd Cluster (3 nodes)      ← Stores cluster state & configs
│   │   ├── etcd-1 (AZ A)
│   │   ├── etcd-2 (AZ B)
│   │   └── etcd-3 (AZ C)
│   ├── Controller Manager           ← Reconciles desired vs actual state
│   ├── Cloud Controller Manager     ← Integrates with AWS (ELB, EBS, etc.)
│   └── Scheduler                    ← Assigns Pods to worker nodes
│
├── Data Plane (Customer-managed)
│   ├── Availability Zone A
│   │   ├── Worker Node 1 (EC2 or Fargate)
│   │   │   ├── Kubelet Agent
│   │   │   ├── Kube-proxy
│   │   │   └── Pods (your apps)
│   │   └── Worker Node 2 (same structure)
│   │
│   ├── Availability Zone B
│   │   ├── Worker Node 3
│   │   ├── Worker Node 4
│   │   ├── Kubelet Agent
│   │   ├── Kube-proxy
│   │   └── Pods
│   │
│   └── Availability Zone C
│       ├── Worker Node 5
│       ├── Kubelet Agent
│       ├── Kube-proxy
│       └── Pods
│
└── Networking (AWS-managed)
    ├── VPC
    ├── Public + Private Subnets
    ├── Internet Gateway (for public access)
    ├── NAT Gateway (for private nodes)
    ├── Elastic Load Balancer (for Services of type LoadBalancer)
    └── Security Groups + Route Tables
```
THE MASTER NODE contains:
Container Runtime (Docker)

kube-apiserver
	is the frontend for the Kubernetes control plane. It exposes the Kubernetes API
	Handles the CLI tools like kubectl, Users and even Master components ( scheduler, controller manager, etcd), Worker node components like kubelet
etcd
	Consistent, highly available key value store used as kubernetes backing store for all cluster data
	It sotres all the masters and worker node info
KubeController manager
	Responsible for noticing and responding when nodes, containers or endpoints go down
	
	Node controller notices when nodes go down
	Replication controller maintains the correct number of pods for every app
	Endpoints controller populates the endpoints object( joins services and pods)
	Service account and Token controller - service account creation and API access for new namespaces

CloudController manager
	Cloud controller manager is responsible for Cloud specific architecture - it embeds cloud specific logic
	Local Kubernetes does not have this component.
	It only runs controllers that are specific to you cloud provider
	Node controller chekcs if a node has been deleted in the cloud anfter is stops responding ( if it was deleted from the cloud then it will auto delete from the k8s cluster)
	Service controller creates, updates and deletes cloud provider load balancer

High level overview:
```text
┌────────────────────────────┐
│        Kubernetes          │
│       Control Plane        │
└────────────────────────────┘
            │
            │ (internal cluster communication)
            ▼
┌────────────────────────────┐    ┌────────────────────────────┐
│        API Server          │◄──►│ Cloud Controller Manager   │
│  (handles kubectl + API)   │    │  (CCM)                     │
└────────────────────────────┘    └────────────────────────────┘
                │
                │ (calls cloud provider API)
                ▼
┌──────────────────────────────────┐
│     Cloud Provider Infrastructure│
│  (AWS, GCP, Azure, etc.)         │
│                                  │
│  ├── Compute (EC2, GCE, VM)      │
│  ├── Load Balancers (ELB/NLB)    │
│  ├── Storage (EBS, PD, Disks)    │
│  └── Networking (Routes, VPCs)   │
└──────────────────────────────────┘

**Kubelet** agent:  it **communicates with the API server**, gets the desired Pod specs, and ensures those containers are running using the container runtime (like containerd or CRI-O).
kubelet is the primary node agent in Kubernetes
It communicates with the API server to receive Pod definitions and ensures that the required containers are running, healthy, and match their desired state.  
It also reports node and Pod status back to the control plane.

**Kube-proxy** is a network proxy that runs on each node.  
It maintains network rules that allow communication **to and from Pods**,  
ensuring connections **inside the cluster (Pod-to-Pod)** and **from outside the cluster (via Services)** work correctly.
sits on Layer 4 TCP/UDP
kube-proxy doesn’t modify Pods directly; it maintains **network rules on the node**, not _inside_ Pods.
**kube-proxy** is a network component that runs on every node

EKS kubernetes - VS kubernetes  - Comparing the Master Nodes

Kubernetes Fundamentals

Pod is a single instance of your app and is the smallest object in K8s
ReplicaSet will maintain a stable set of replica Pods running at any given time - it guarantees the availibility of the identical Pods
A Deployment runs multiple replicas of you application and automatically replaces any instances that fail or become unresponsive. Does handle roll-out and roll-back changes to apps. Deployments are good for statelss applications. Stateless apps do not remember theys past state. They mostly send data to other apps, and not store themselves. 
Service sits in front of one or more Pods and **acts as a built-in load balancer**, distributing traffic evenly among them.
Service practically sits in front of a POD and acts as a load balancer


##############
EKS commands for cluster creation and checking

eksctl create cluster --name=eksdemo1 \
                      --region=us-east-1 \
                      --zones=us-east-1a,us-east-1b \
                      --without-nodegroup 

aws eks update-kubeconfig --name eksdemo1 --region us-east-1

The above command is the moment that we switch from AWS infrastructure creation to Kubernetes API (kubectl )writes to the k8s API that interacts with EKS cluster 
by running the above command the following gets created for local Kubernetes:
  adds a new cluster entry (endpoint + certificate),
  adds a user entry (with AWS IAM exec plugin),
  adds a context entry (that links the two),
  and marks that context as current.
  
kubectl config current-context # checkout if autoswitched to cluster
to check this out.
eksctl get cluster  
kubectl get svc


 OIDC - a **way to log in** (authentication) that apps and systems can use to trust each other without storing passwords or static keys.
```
eksctl utils associate-iam-oidc-provider \   
    --region region-code \
    --cluster <cluster-name> \
    --approve

 Replace with region & cluster name
eksctl utils associate-iam-oidc-provider \
    --region us-east-1 \
    --cluster eksdemo1 \
    --approve

Create Public Node Group   
eksctl create nodegroup --cluster=eksdemo1 \
                       --region=us-east-1 \
                       --name=eksdemo1-ng-public1 \
                       --node-type=t3.medium \
                       --nodes=2 \
                       --nodes-min=2 \
                       --nodes-max=4 \
                       --node-volume-size=20 \
                       --ssh-access \
                       --ssh-public-key=kube-demo \
                       --managed \
                       --asg-access \
                       --external-dns-access \
                       --full-ecr-access \
                       --appmesh-access \
                       --alb-ingress-access 

From the console we need to update sercurity groups to allow all traffic 0.0.0.0 on worker nodes
	eks-cluster-sg-<cluster-name>-randomid
    eks-node-sg-<cluster-name>-randomid
```
List EKS clusters
eksctl get cluster

List NodeGroups in a cluster
eksctl get nodegroup --cluster=clustername

List Nodes in current kubernetes cluster
kubectl get nodes -o wide

Our kubectl context should be automatically changed to new cluster
kubectl config view --minify

How to check if this resource exists: 
    aws s3 ls --region us-east-2 | grep mlops-tofu-state
    Should return date/time/name of resource

DynamoDB check:
    aws dynamodb list-tables --region us-east-2
    should return a json with name

terraform outputs:
Should return:
    tf_state_bucket = "mlops-tofu-state"
    tf_locks_table  = "mlops-tofu-locks"


CLI VPC check
    aws ec2 describe-vpcs --region us-east-2 --query "Vpcs[].{ID:VpcId,CIDR:CidrBlock}"

CLI get Subnets
    aws ec2 describe-subnets --region us-east-2 --filters "Name=vpc-id,Values=vpc-0aae990c4109f5877" \
    --query "Subnets[].{ID:SubnetId,CIDR:CidrBlock,AZ:AvailabilityZone}"

CLI get NAT gateways
    aws ec2 describe-nat-gateways --region us-east-2 --filter "Name=vpc-id,Values=vpc-0aae990c4109f5877" \
    --query "NatGateways[].{ID:NatGatewayId,Subnet:SubnetId,State:State}"

```



DEFINING resources ( EKS transition to kubectl)

A namespace is just a logical grouping of K8s resources that represent a virtual cluster within a physical cluster
It is used to organize, isolate and manage resources such as Pods, Services, and Deployments that belong to the same application, team, environment.
Each namespace can have: 
	its own resource quota
	access controls RBAC
	own network policies
General usage of namespaces:
	default - general workloads
	dev - deveopment environment
	staging - pre-production testing
	prod - production workloads
	kube-system - system components like CoreDNS, KubeProxy, etc


A context is a connection configuration - it tells kubectl which cluster to talk to and which user and in which namespace by default
Bellow a yaml showing this:

contexts:
 -name: arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
   context:
    cluster: arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
    user: arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
    namespace: default

kubectl config current-context 
kubectl config create-context 
kubectl config use-context contextname # to switch to other context names

examples of used commands to clear a cluster:
kubectl config delete-context arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
kubectl config delete-cluster arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
kubectl config unset users.arn:aws:eks:us-east-2:716969406947:cluster/mlops-infra-aws-eks
kubectl config delete-user my-user

kubectl config unset current-context

In the case of users, if a user is deleted or unset, kubectl removes the authentication data : tokens, certifications or AWS IAM exec plugin for that user. Any attempt to connect will fail. The cluster itself is untouched.
kubectl config unset users.username  deletes the local auth data for that user.


aws eks commands and kubectl
aws credentials must be setup in aws configure in order to use aws configure
These two tools are used for administration.
With aws eks commands you are creating and configuring the cluster.
aws eks create-cluster \   # this creates the control plane, api server, etcd, controllers but no worker nodes yet
  --name my-cluster \
  --region us-east-2 \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/EKS-ClusterRole \
  --resources-vpc-config subnetIds=subnet-abc123,subnet-def456,securityGroupIds=sg-0011223344
  
You can check the progress with this command:
	aws eks describe-cluster --name my-cluster --region us-east-2
	
You can add nodegroups that will run the pods 
aws eks create-nodegroup \
  --cluster-name my-cluster \
  --nodegroup-name my-node-group \
  --subnets subnet-abc123 subnet-def456 \
  --scaling-config minSize=1,maxSize=3,desiredSize=2 \
  --ami-type AL2_x86_64 \
  --instance-types t3.medium \
  --node-role arn:aws:iam::<ACCOUNT_ID>:role/EKS-NodeInstanceRole
You can check the nodegroup status:
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name my-node-group

After the nodes are ready we can connect our local machine and use kubectl
aws eks update-kubeconfig --region us-east-2 --name my-cluster
kubectl config current-context
kubectl get nodes
kubectl get namespaces

kubectl create namespace dev
kubectl apply -f deployment.yaml
kubectl get pods -n dev
kubectl expose deployment myapp --port=80 --type=LoadBalancer
From this point forward, **you’re no longer using `aws eks`** — everything happens through the **Kubernetes API** via `kubectl`

A diagram to understand where the shift to kubectl is made:
[ aws eks create-cluster ]       → creates control plane
[ aws eks create-nodegroup ]     → adds worker nodes
[ aws eks update-kubeconfig ]    → configures local access # this is the command that binds aws eks to kubectl
[ kubectl get nodes ]            → talks to cluster via API
[ kubectl apply -f app.yaml ]    → deploys workloads



Kubernetes PODs

Kubernetes has the goal of deploying apps in the form of containers on worker nodes that live inside a cluster

A pod is a single instance of an application

K8s does not deploy containers directly on worker nodes instead the container is encapsuleted into a Kubernetes object named POD
The goal is to deploy apps in the form of containers on worker nodes in a k8s cluster
K8s does not deploy containers to worker nodes.
Pods are the ones that are running the containers.
A pod is a single instance of an app
A **Pod does not have a fixed number of clients** it can handle.  
It depends entirely on **what’s running inside the container(s)** — the **application logic**, **resources (CPU/RAM)**, and **traffic load**.
If your Pod runs **NGINX**, it can handle **hundreds or thousands** of clients (depending on configuration and hardware).
If your Pod runs a **small Flask app** with one worker process, it may handle only **a few concurrent requests**.
Two nginx containers in a single pod with the same purpose is not recomended.
You usually have **one main (unique) container** in a Pod,  
but you **can include other different containers** (sidecars) that assist it —  
for logging, proxying, monitoring, or initialization tasks.
Helper containers or Sidecars are data pullers, data pushers (logs), proxies ( write static data to html files using Helper container and reads using main container)
Pod to container is a one to one relationship and share same storage space

The following command are imperative! Meaning that you write them through the CLI ( declarative means YAML files )



Using pods and checking inside
minikube start
minikube ip  # get ip adress of the control plane
kubectl get nodes -o wide  # if no pods exist, create pods

**In managed clouds → the provider picks (always containerd)**
minikube ssh    # you can ssh into the minikube container  to see what is running the containers (dockerd, contanerd, CRI-o, etc)
	ps aux | grep containerd  # if containerd is used
	( you can start running images with other runtimes like:
	minikube start --container-runtime=containerd   or
    minikube start --container-runtime=docker )
	kubectl describe node | grep "Container Runtime Version"
	
	
Create pod:
	kubectl run running-pod --image stacksimplify/kubenginx:1.0.0  # image name
	kubectl describe pod runningpodv1
	kubectl exec -it runningpodv1 -- bash
	kubectl delete pod namepod

minikube status # to see if cluster has started
kubectl get pods -o wide
kubectl exec -it containerID -- sh  # to get the 
kubectl describe pod my-first-pod | grep State  # case sensitive because of YAML

Go inside the container and see what ports is Nginx running:
kubectl exec -it podname -- sh
Then inside container:
cat /etc/nginx/conf.d/default.conf | grep listen

Expose the POD:

kubectl expose pod my-first-pod \
  --type=NodePort \
  --port=80 \
  --target-port=80 \
  --name=nginx-service

kubectl get svc
minikube service nginx-service --url #  this will output the URL # minikube command is only for local testing of course -> use the next one for remote contexts
**kubectl port-forward service/nginx-service 8080:80**



Debug if needed 
If you need to debug the POD - OR use Ephemeral containers ( must read more )
This starts a **temporary container** inside the same pods network namespace ( not inside the bugged pod) that does_ include debugging tools:
kubectl debug pod/nameofbuggedPOD -it --image=busybox
ps aux
top
netstat -tulpn


Kubernetes Services = NodePort  ( service object is an endpoint for pods)

Creating a service means using kubectl expose podname --type=NodePort --port=80 --name=give-service-a-name
You can expose and app running on a set of PODs using different types of services 
Cluster IP # expose the actual cluster IP to the internet 

NodePort
	Exposes the service on each worker node's IP at a static port (nothing but NodePort)
	A ClusterIP Service to which the NodePort service routes is automatically created.
	Port Range 30000 - 32767
	Every service has it;s own port
		Cluster IP service port : 80
	Diagram overvirew:
```text
╔══════════════════════════════════════════╗
║           Kubernetes Cluster             
║──────────────────────────────────────────
║                                          
║  Control Plane                        
║   ├─ API Server                          
║   ├─ Controller Manager                  
║   ├─ Scheduler                           
║   └─ etcd                                
║                                          
║  Worker Node(s)                       
║   ├─ Kubelet                             
║   ├─ Kube Proxy                          
║   └─ Container Runtime (containerd)      
║        │                                 
║        ├─ Pod                            
║        │   ├─ Container (your app)       
║        │   └─ Container (sidecar)        
║        │                                 
║        └─ Service                        
║            (ClusterIP / NodePort / LB – internal + external communication)
╚══════════════════════════════════════════╝
```

Kubernetes cluster:
	Worker Node
		POD
		SERVICE ( assigns the cluster IP service port to port: 80 and the target container Pod to targetPort: 80   This means the actual port mapping ipadress/80:80 !

YAML example of this:
	apiVersion: v1
kind: Service
metadata:
  name: my-nginx
spec:
  selector:
    app: nginx
  ports:
    - port: 80          # Service Port
      targetPort: 80    # Pod container port
  type: ClusterIP

targetPort  -> Inside the Pod   ->  The port the container actually listens on.

port  ->  Inside the Service (ClusterIP)  ->  The port exposed inside the cluster. Other Pods use this.

nodePort   ->  On the Node (VM/host)  ->  The port opened on each worker node to reach the Service from outside the cluster.

Declarative example YAML: 
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  type: NodePort
  selector:
    app: myapp
  ports:
    - port: 80          # (1) Service port
      targetPort: 8080  # (2) Pod's container port
      nodePort: 30080   # (3) Node's exposed port

External client
    │
    ▼
NodeIP:30080            ← NodePort (worker node port) (exposed on the node at host-level)(This is the actual VM IP) Never use in production, only for testing and degubbing
    │
    ▼
Service ClusterIP:80     ← internal virtual IP and port ( inside cluster meaning it's private)
    │
    ▼
PodIP:8080               ← actual container port (container private IP)

If you had multiple worker nodes, **each one** opens the same NodePort (30080).  
Kubernetes (via kube-proxy) will route your request to one of the backend Pods, even if that Pod lives on another node.

Node1IP:30080
Node2IP:30080
Node3IP:30080

`ClusterIP` = internal only  
`NodePort` = local/external access via NodeIP:port  
`LoadBalancer` = cloud-level IP built on top of NodePorts

Kubernetes automatically wires up the NodePort on every node, even if the Pod isn’t there. That’s why we can curl either node’s public IP and still get the same webpage — Kubernetes routes the traffic internally to wherever the Pod actually runs. This means that in order for kubernetes to not have dead adresses on the service, it routes existent but non working nodes to the ones that work. This way the client never runs into 404
If that Pod dies, kube-proxy removes it from the Service endpoints.  
When a new Pod starts (even on another node), the Service updates its routing instantly

Doing it:
Service gets created accoross the worker nodes, meaning that you can access the app on multiple worker node ports

kubectl run runningpodv1 --image imagenamefromDockerHub
kubectl expose pod runningpodv1 --type=NodePort --port=80 --target-port=80
kubectl describe pod runningpodv1
kubectl get nodes -o wide   # this will expose 
kubectl get svc
minikube ip # to get the local minikube ip where the cluster is running
minikube service runningpodv1 # because of port forwarding in Win11, we create a tunnel for service that browser can use

```text
┌───────────┬──────────┬─────────────┬───────────────────────────┐
│ NAMESPACE │   NAME   │ TARGET PORT │            URL            │
├───────────┼──────────┼─────────────┼───────────────────────────┤
│ default   │ nginxpod │ 80          │ http://192.168.49.2:30381 │
└───────────┴──────────┴─────────────┴───────────────────────────┘
🏃  Starting tunnel for service nginxpod
┌───────────┬──────────┬─────────────┬────────────────────────┐
│ NAMESPACE │   NAME   │ TARGET PORT │          URL           │
├───────────┼──────────┼─────────────┼────────────────────────┤
│ default   │ nginxpod │             │ http://127.0.0.1:34563 │
└───────────┴──────────┴─────────────┴────────────────────────┘
```

- **`kubectl expose`** creates a Service object that maps the container’s internal port (80) to a node-level NodePort (for example 30381).
    
- **`minikube ip`** gives the IP of the Minikube VM that hosts the control plane and worker node(s).
    
- In **Windows 11 + WSL2**, the `192.168.49.x` network is isolated from the host,  
    so **`minikube service`** automatically creates a **localhost tunnel** (`http://127.0.0.1:<port>`) that your Windows browser can access.


kubectl expose pod command variations:
kubectl expose pod runningpodv1 --type=NodePort --port=80 --name=runningpodv1-service # this assigns a new pod to the already RUNNING service!. You can delete pods, recreate and reasign so they do not remain orphan and exclude the recreation of the service itself


LoadBalancer(an entrypoint)  ( sits on top of Nodeport then nodeport sends to Cluser IP, cluster sends to Pods. You can either use NodePort as exposed public ( an IP adress, or let LoadBalancer do the work ) ) Every one of these is managed by Kubernetee Service


Pod Container access and logs:

	Get loggs from pods

	kubectl logs podname
	kubectl logs -f podname  #  You can stream loggs in the CLI to see them live:
	Executing commands:
	
	kubectl exec -it nginxpod -- bash  # this is to get inside bash shell container
	You can run commands into the container from outsite
	kubectl exec -it nginxpod ls
	kubectl exec -it nginxpod cat /usr/share/nginx/html/index.html
	
	Get YAML outpus of Pod service
		kubectl get pod nginxpod -o yaml
		kubectl get service nginxpod -o yaml # you get the service of the pod
		kubectl get service -o yaml  # or get everything about service in YAML
kubectl get service nginxpod -o yaml | grep port # or grep whatever you want

Deleting stuff:
	kubectl get all  # see pods, services. etc
		kubectl delete pod podname
		kubectl delete svc servicename

Replica sets

Hogh availibiliry or realiability
Scaling
Loadbalancing
Labels and selectors

If a pod dies, ReplicaSet recreates the configured pod to ensure the configured no of pod running at any given time 

**ReplicaSets** ensure that a defined number of identical Pods are running simultaneously.  
For example, if it’s set to 3 replicas, Kubernetes keeps 3 Pods active at all times.  
If one Pod crashes or is deleted, the system automatically creates a new one to restore the total number of running Pods back to 3 (or whatever number is defined).
**ReplicaSet = Self-healing Pod controller**  
Keeps the desired number of Pods running by automatically replacing any that fail.


LoadBalancing: 

LoadBalancer (an entrypoint)  (sits on top of Nodeport then nodeport sends to Cluser IP, cluster sends to Pods. You can either use NodePort as exposed public ( an IP adress, or let LoadBalancer do the work ) ) Every one of these is managed by Kubernetee Service

Provides load balancing meaning that the client cannot overload traffic to a single pod.
K8s provide load balancing out of the box using Service for the pods which are part of a ReplicaSet
Labels & Selectors are the jey itmes which ties all 3 - Pod -> ReplicaSet -> Service
ReplicaSets can be over mode worker nodes!!!

Service distributes traffic through the ReplicaSet and then to the Pods present in that set
Bottom line is : 
- **ReplicaSet = quantity control (availability)**
    
- **Service = traffic control (load balancing)**

Scaling : When toe load becomes greater than the number of pods, k8s enables us to scale up our app adding additional pods as needed

You can scale manually or enable HorizontalPodAutoscaler

Replica Sets are only declarative though YAML manifests

Using replica sets:

First you create the YAML file in your project folder
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: my-helloworld-rs
  labels:
    app: my-helloworld
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-helloworld
  template:
    metadata:
      labels:
        app: my-helloworld
    spec:
      containers:
      - name: my-helloworld-app
        image: stacksimplify/kube-helloworld:1.0.0
```
SERVICE IS NOT SELF HEALING # if you delete it, it will no be autocreated
```
kubectl get replicaset
kubectl get rs
kubectl describe rs my-helloworld-rs
kubectl get pods # to see the pods created
kubectl get pods -o wide
kubectl get pods -o yaml
kubectl get pod podname -o yaml
kubectl get pods myhelloworld-rs-c8rrj -o yaml # get which replica set the pod belongs to

kubectl expose rs replicasetname --type=NodePort --port=80 --target-port=8080 --name=servicenametobecreated
kubectl port-forward svc/kodecolor-imperative-deploy-service 8080:80
kubectl get svc
kubectl get nodes -o wide # get worker nodes public IP

#Verify if the repocaset availibility feature is working
Update the replica sets from 3 to 6
kubectl replace -f replicaset-demo.yaml
kubectl get pods -o wide # see the new pods or not

#Delete replica sets
kubectl delete svc servicename # the pods will continue to be run(managed) by replicaset
#you can reattach the service to the pods
kubectl expose pod runningpodv1 --type=NodePort --port=80 --name=runningpodv1-service
kubectl get pods my-helloworld-rs-2zp2k -o yaml | grep -A 20 owner # grep first 20 lines after owner to you do not clog up the terminal


```

Expose replica set as a service.

Tunneling is for local bridging WSL2 to Windows browser:
```
kubectl expose rs my-helloworld-rs --type=NodePort --port=80 --target-port=8080 --name=my-helloworld-rs-service
kubectl get svc
kubectl port-forward svc/kodecolor-imperative-deploy-service 8080:80

now modify the replicas in the YAML file to 6 and then hit:
kubectl replace -f nameofyamlfile.yaml
kubectl get pods -o wide # to see if they got created

kubectl delete svc
kubectl get svc # to see if it got deleted
```


Deployments:
Deployments are a superset of replica set. Replica set is a small subset of the deployment features
You never need to create pods manually — **ReplicaSets and Deployments do it implicitly from the Pod template.**
A **Deployment** is basically a **ReplicaSet manager** — it wraps ReplicaSets and adds **version control, rollout management, and rollback capabilities** on top of them.
Whenever we create a deployment we rollout a replicaSet also
When using deployments you keep previous versions of the setup - You can rollback to older deployments or update, scale , pausing and resuming a deployment 
**Deployment → manages → ReplicaSet(s)**  but **not the other way around**.
It contains the last 10 versions of our application, or add more versions with .yaml files
Cleanup policy automated
Canary deployments ?

Creating a deployment the imperative way - through commands in CLI ( not YAML )

```
minikube start -p myclustername
kubectl config get-contexts
kubectl config set-context contextname

kubectl create deployment dploymentname --image=kodekloud/webapp-color
kubectl get deployments
kubectl describe deployment my-first-deployment
kubectl get rs
kubectl get po
kubectl scale --replicas=20 deployment/my-first-deployment
kubectl get deploy
kubectl get rs

kubectl scale --replicas=10 deployment/my-first-deployment 
kubectl get deploy
kubectl expose deployment my-first-deployment --type=NodePort --port=80 --target-port=80 --name=my-first-deployment-service

kubectl port-forward svc/kodecolor-imperative-deploy-service 8080:80 #WSL2 problem

# Get Public IP of Worker Nodes
kubectl get nodes -o wide


```

Creating a deployment the declarative way ( YAML file )


Updating or editing deployments:
You can set a new image or edit the edployment

Update deployment Imperative way: 
```
kubectl get deployment deploymentname -o yaml

# check container name in YAML file
kubectl set image deployment/kubecolor-deployment containername=stacksimplify/kubenginx:2.0.0 # container name with kubectl describe pods | grep "Containers:"
# it is good to annotate to see history in rollout
kubectl annotate deployment kubecolor-deployment \ 
kubernetes.io/change-cause="Updated to Juice Shop v1 for demo"  # if you do not annotate the change you will not see the change in rollout history
kubectl annotate <resource-type>/<resource-name> <key>="<value>"

kubectl rollout history deployment/kubecolor-deployment 



kubectl rollout status deployment/my-first-deployment
kubectl describe deployment my-first-deployment
kubectl get rs
kubectl get po
kubectl rollout history deployment/deploymentname
kubectl port-forward svc/kodecolor-imperative-deploy-service 8080:80 #WSL2 problem
kubectl port-forward svc/kubecolor-deployment 9090:3000 # 9090 will be the targer for the browser and 3000 is the target for the container app


```

Edit the deployment Declarative way:

```
# With kubectl edit you can get inside the declared YAML file in K8s
kubectl edit deployment/my-first-deployment
# opens with VIM. kubectl edit is just for testing, should no be used in production. You do not have a version control of this and if you mess something up there will be no track of it.
# kubectl rollout history deployment kubecolor-deployment  # If you use kubectl edit, the changes are not registered anythere, neither in rollouts

# Change From 2.0.0
    spec:
      containers:
      - image: stacksimplify/kubenginx:2.0.0

# Change To 3.0.0
    spec:
      containers:
      - image: stacksimplify/kubenginx:3.0.0
        
        #bellow the image setting for the new image
        
kubectl get deployment kodecolor-imperative-deploy -o yaml | grep name:  # to get container name where to insert the image

# the trigger for the image replacement is the kubectl set image  command itself. 
kubectl set image deployment/kodecolor-imperative-deploy webapp-color=stacksimplify/kubenginx:2.0.0
# kubectl rollout is just a short log
kubectl rollout status deployment/kodecolor-imperative-deploy



```
If you did the annotations correct when if we hit:

kubectl rollout history resource/deploymentname  # you should see the numbers of revisions. Choose the suitable that we want to roll back to!!! Not the one you want to remove

kubectl rollout history deployment/kubecolor-deployment # now you have rolled back to that particular state

kubectl rollout undo deployment/kubecolor-deployment --to-revision=3 # you remove the current version and change to revision 3 / You cannot execute this commmand if there was no previous command to undo

TO restart the while application:
kubectl rollout restart deployment/deploymentname
kubectl get pods

Pausing and resuming deployments

# If we want to make multiple deployments we can pause the deployment and make changes and resume

kubectl rollout pause
kubectl rollout resume
kubectl get endpoints myapp-service

kubectl delete deploy nameofdeploy
kubectl delete svc svcname

Kubernetes services

Cluster IP - used for comunication inside the cluster # frontend to backend for example
NodePort - Access apps outside of K8s using Worker node ports
LoadBalancer - AWS elastic load balancer
Intress - Advanced load balancer, SSL, etc de invatat
externalName - To access externally hosted apps or databases inside you k8s cluster. DNS name  de invatat cum functioneaza

YAML FILES -> The declarative way that is good for keepind track of versioning

# the base definition of a resource in K8s
Tipycal resources to be created: Pod, ReplicaSet, Deployment, Service
```
apiVersion: v1        # string
kind: Pod             # string
metadata:             # dicitonary - contains more pairs
  name: my-yaml-pod
  labels:
    app: my-yaml-app-v1
spec:
  containers:
    - name: my-app-containername  # the container name that is is used when setting the image in rollouts
	  image: repo/imagename   # image name in dockerhub
	  ports:
	    - containerPort: 80
```
apiVersion: V1   # V1 is the core Kubernetes API for basic objects like pods, services, ConfigMaps ( deployments use V1 )
kind: Service    #defines what type of resource you are creating
metadata:
  name: my-yaml-app-v1-service   # the unique name of your serrvice (can be annotations, labels, names)
spec:                 #defines behavior or configuration of this service
  type: NodePort       # can be Cluster IP(inside cluster comunication), NodePort(access from outsire the cluster - local using browser),Loadbalancer(cloud), external DNS name 
  selector:           
    app: my-yaml-app-v1  # api version keeps depending on what you want to build
  ports:
    - name: http # assign a name to a port for easy identify
      port: 80  #service port exposed outsite
      targetPort: 80  # the container port targeted in the cluster and further into the pod ( where the container lives)
      nodePort: 31231  #underneath the nodePort there is the above targetPort

# pods forward all container data tot the cluster
# all containers in the POD share the same IP # if the containers listens in port 80, the Pod itself also listens on 80
# You do not need NAT or explicit port firwarding betweeen pods (k8s handles this through CNI - Container network interface)

# A Pod runs containers and provides a network endpoint to access them from within the cluster
User (your browser)
   │
   ▼
<NodeIP>:nodePort (external entry on the node)
   │
   ▼
Service port (virtual cluster-wide port)
   │
   ▼
Pod IP:targetPort (actual container inside the cluster)

USING YAML files
```
The context selector before applying so you do not destroy some other cluster
kubectl config current-context 
kubectl config use-context  # context are a combination of cluster+user(credentials) + namespace - Only one cluster at a time!!! Namespaces can overlap multuple clusters and/or resources

kubectl config create-context # if you need a new context - contexts are logical mappings or resources - just a saved connection profile inside your kube configuration -> When I use this context, talk to that cluster, as this user, in this namespace.
kubectl config set-context   # With this you can set a context to another user and combine resources. A new context can map a resource like a cluster to a user and a namespace so you can let in someone else to work on that cluster - a context is just linking setting that already exist. 

kubectl config use-context contextname # to switch to other context names
kubectl create name-of-yaml.yaml # this commands only creates new resources - does not update old ones
kubectl apply -f name-of-yaml.yaml  # Updates existing resources

apiVersion: v1
kind: Service
metadata:
  name: myapp-pod-nodeport-service 
spec:
  type: NodePort 
  selector: #only to those puds under the selector the traffic will be routed!
    app: myapp 
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
      nodePort: 31231 # NodePort


How the app name gets declared from one script to another

# Deployment (creates Pods)
metadata:
  name: myapp-deployment
spec:
  selector:
    matchLabels:
      app: myapp        # Must match Pod label
  template:
    metadata:
      labels:
        app: myapp      # Pods get this label


apiVersion: v1
kind: Service
metadata:
  name: myapp-service
spec:
  selector:
    app: myapp          # Must match Pod label again
  ports:
    - port: 80
      targetPort: 80  # port inside container

```

Deployment
  ↓
ReplicaSet
  ↓
Creates Pods using template:
   - metadata.labels = app: myapp
   - spec.containers[0].image = nginx:latest
  ↓
Service
   - selector.app = myapp  (targets Pods)
   - spec.ports:
        - port: 80
          targetPort: 80
          nodePort: 31231 (if NodePort type)
  ↓
Ingress (optional)
   - routes HTTP(S) traffic to Service
   - spec.rules.host = myapp.example.com
   - spec.backend.service.name = myapp-service



The Deployment defines the Pod template, the ReplicaSet ensures Pods exist, the Service connects users to those Pods, and the Ingress (if used) exposes them externally

template = Pod template
It defines what each Pod should look like when the controller (Deployment or ReplicaSet) creates it.

tier is not a Kubernetes object or isolation boundary — it’s just a label.
But it’s incredibly useful as a logical grouping tag for your resources.


EKS
How does a POD comunicate with other AWS services?
PIA - Pod Identity Agent - go to addons and install pod identity agent

You need a pod deployed in EKS, and assign an IAM role to it ( practically create a user with IAM permission to manage pod )
0. We are going to create a pod identity assiciation - a simple CLI pod # the pod will run on each and every node on the cluster
1. The IAM role will have read only permissions to S3 for example
2. We are going to install PIM -> Then Create a service account for CLI Pod
3. In which namespace the workload is running?

You need to restart the pod in order for the permissions to take effect
aws s3 list ( will work after pod restart )
Eks pod identity association (PIA) works for Dynamo, EBS and other services

Installing EKS PIA ( pod identity association ) 
You practically create a pod inside all the worker nodes ( you can actually se a pod with a agent name when kubectl get pods -n namespace or kubectl get daemonset -n namespace )

It is a Daemon that handles authentication of services and lives in a simple pod inside each worker node in the cluster
kubectl get daemonset -n namespacename
kubectl get pods -n kube-system
eks-pod-identity-agent  will be present in the list - it runs on each k8s worker node after install
kubectl	get pods -o wide

In the YAML files you have the namespace defined : default
Run the YAML files that create the service account:

ServiceAccount is another Kubernetes ( or EKS ) object that lives inside the cluster’s control plane, not in your nodes or containers.
A Service account is to a pod what a username is to a person. The pod authenticates to the API server


EBS volumes 
EBS provides block level storage volumes for use with EC2 and container instances
We can mount these drives as devices on out EC2 and container instances
EBS volumes that are attached to an EC2 persist independently from the life of the EC2 container instance
We can dinamically change the config of a volume attached to an instance ( increase/decrease size etc ) - works for databases for short and long reads of service

For Cluster IP service, the following will live inside :
Storage class
Persistent Volume Claim
ConfigMap
Env Variables
Volumes
Volume mounts
Node port for local

FOr User management we create a NodePort Service

Node Port service
Deployment
Env variables 

CSI drive: CSI stands for Container Storage Interface —
a standard API that allows Kubernetes to talk to any storage backend (AWS, GCP, Ceph, etc.) through a plug-in driver.



Pod is running

```
The EBS volume is attached and mounted to that node.
The application writes data into /data, which goes to EBS.
Pod dies / Node drained
If a Pod is rescheduled to another node, the data volume moves with it
Kubernetes terminates the Pod.
The EBS CSI driver detaches the volume from that EC2 node.
Replica / new Pod scheduled
The controller (Deployment, StatefulSet) spins up a new Pod (often on another node).
The CSI driver sees that this Pod uses the same PVC.
It attaches the same EBS volume to the new node.
The volume is remounted inside the new Pod at /data.
Application continues
```

The new Pod now sees all previous data — files, databases, etc. — intact.

EBS volumes are ReadWriteOnce (RWO), meaning they can only be attached to one node at a time.
So if you have multiple replicas, only one Pod can use that volume simultaneously.
For shared access, you’d use EFS (Elastic File System) instead.
The driver handles: AWS API calls: AttachVolume, DetachVolume, DeleteVolume
Node mount paths and filesystem integrity
The delay between Pod death and new Pod readiness = time for AWS to detach + attach (~5–20 seconds).

Installing EBS CSI driver:
Go to EKS cluster (name of your cluster) - Addons - EBS CSI driver -> Addon access is EKS Pod Identity -> Create recomended role ( sends you to IAM ) -> EKS pof Identity -> Create role  - Go to Roles and see what we created. Now we have Pod identity - must have Active status

kubectl get pods -n namespacename
You shold see ebs-csi in front of nodes

DaemonSet is a controller that manages system-level Pods which run services on every node in the cluster
kubectl get ds -n nameofnamespace  # this gets Daemonsets in the namespace
With this command you are seeing real Pods that are running on your worker nodes, just like your own application Pods. The pods are system-level Pods, managed by DaemonSets

A DaemonSet is a Kubernetes controller that ensures one Pod runs on every node (or on a selected subset of nodes).
It’s used for workloads that need to:
collect logs, metrics, or monitor nodes
provide node-level system services
mount or manage node-local storage or networking


kubectl get endpoints myapp-service

Terraform infra creation:

```
Concept	Rule
Backend	Always defined in root, never in modules
State bucket & lock table	Created once, before using backend
Modules	Must contain only resources + their own inputs/outputs
Root	Only orchestrates (wires modules together)
Variables	Come from root → flow downward
Outputs	Come from modules → flow upward
```


```
Why terraform.tfvars exist -> It is only for values you want to override without editing main.tf. The usage of it is optional. If you do not write values in tfvars then TF will use the ones in root/main.tf

terraform.tfvars       (optional)
         ↓
root main.tf (module "eks" call)
         ↓
modules/eks/variables.tf  (declares inputs)
         ↓
modules/eks/main.tf       (uses inputs)
         ↓
terraform-aws-modules/eks/aws (real cluster creation)

```
```
!!!!!!!Module folder skeleton!!!!!!!!!
terraform.tfvars → variables.tf → main.tf → outputs.tf


# modules/<name>/main.tf
# resources or upstream registry module

# modules/<name>/variables.tf
variable "example" { type = string }

# modules/<name>/outputs.tf # use only outputs from registry! You cannot invent your own output namings. They are already predefined.
output "example_out" { value = something }
```
```
Root module call
module "<name>" {
  source = "./modules/<name>"
  # map root vars to module vars 
```
```
Pass outputs between modules
module "b" {
  source = "./modules/b"
  from_a = module.a.example
```
```
NAT/EIP pattern (choose one)
# A) Let VPC module create EIPs
vpc_reuse_nat_ips       = false
vpc_external_nat_ip_ids = []

# B) Reuse precreated EIPs
resource "aws_eip" "nat" {
  count  = var.vpc_single_nat_gateway ? 1 : length(var.vpc_azs)
  domain = "vpc"  # provider v5+
}

vpc_reuse_nat_ips       = true
vpc_external_nat_ip_ids = aws_eip.nat[*].allocation_id  # or .id if olders
```

You use resource block if you are defining everything in main.tf  else: we use modules and we only create modules and call variables. We want something reusable and will choose modular version

Each Terraform module as a function in a programming language.
The child module (modules/vpc) defines how a VPC is created and what outputs it makes available.
The root module (main.tf at the top level) is your main script — it can:
Call the module (like calling a function)
Read the module’s outputs
Optionally decide which of those outputs to “show to the outside world”


```
They refer to different conceptual things:

Name	Type	Meaning	Direction
vpc_cidr	variable	the input value you provide to create the VPC	input → AWS
vpc_cidr_block	output	the CIDR block AWS actually assigned (same value, but now known output)	output ← AWS

In most cases, they’ll have identical values — but semantically they’re not the same thing:

var.vpc_cidr = what you asked for

vpc_cidr_block = what AWS created (and Terraform confirmed)

In plain words: We tell Terraform: use this vpc_cidr to create the VPC.
After creation, AWS gives us back a vpc_cidr_block.
We pass that value up from the registry module → our wrapper -> the root output

So yes, they represent the same network range,
but they flow in opposite directions . vpc.cidr is input variable and vpc_cidr_block is output variable outputted by AWS back to Terraform
```

###########
So in a modular layout you paste the VPC (template from terraform registry) in root module folder in main.tf, you take the values from an VPC template from module/vpc/main.tf, put them into a terraform.tfvars, and then write variables.tf for defining strings or whatever, then define the outputs.tf.
###########
The actual usage of modular layout in Terraform

Get the pattern for the resource from Terraform registry, copy it and paste it in the project/module/main.tf

For example:
"name" and "cidr" are input variables(not names I come up with). Meaning name=var.vpc_cidr means input_variable = type_of_value.the_string_name_defined_in_tfvars

```
| File                              | Purpose                                                   | When to Define Variables                                   | Example                                           |
| --------------------------------- | --------------------------------------------------------- | ---------------------------------------------------------- | ------------------------------------------------- |
| **modules/eks/variables.tf**      | Declares the inputs that the *EKS module itself* needs    | **When `modules/eks/main.tf` references `var.*`**          | `variable "name" { type = string }`               |
| **root/variables.tf**             | Declares inputs to the *root module* (the entire project) | **When `root/main.tf` references `var.*`**                 | `variable "kubernetes_version" { type = string }` |
| **terraform.tfvars** *(optional)* | Provides actual values that override variables            | **When you want to configure values without editing code** | `name = "plasticmemory-eks-cluster"`              |

terraform.tfvars      (optional user-defined values)
        ↓
root/main.tf          (passes values into modules)
        ↓
root/variables.tf     (declares what the root accepts as input)
        ↓
modules/eks/main.tf   (uses values internally)
        ↓
modules/eks/variables.tf  (declares what the module accepts as input)
        ↓
terraform-aws-modules/eks/aws  (creates actual AWS resources)

```


Replace hardcoded values with var.nameofthevariable 
Like this:
From this:

modules/vpc/main.tf
```
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"   #this ends up pulling from the public registry and downloads locally 

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false  # because we are using VPC endpoints and everything remains in the cloud.
  enable_vpn_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```


To this:
modules/vpc/variables.tf
```
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = var.enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  tags = var.tags
}
```
Then define outputs:
modules/vpc/outputs.tf
These outputs are exposed only to Terraform. If we want to expose the VPC ID for example in AWS CLI, we have to declare this output to root/outputs.tf also. The root is the orchestrator
Terraform registry -> https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest#output_default_vpc_cidr_block  Ctrl+F  and search out Outputs to scroll for full list
The name of the output itself is given by you but the value must be linked to an existent resource in main.tf

```
output "vpc_name" {
  value       = module.vpc.vpc_name
description = "VPC for EKS project"
}

output "vpc_id" {   
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}
```


VPC_ENDPOINTS:

This module binds the created endpoints (a route) inside a VPC to an AWS service! This does not expose anything to the internet. 

Terraform defines the infrastructure endpoints — the pieces through which services communicate —
and then AWS binds them together via references (like target_group_arn, subnet_id, vpc_id, etc.)

When you declare an endpoint for an S3, this means that endpoints are created for any S3 created in the future in that VPC

########################################################################


After the VPC and EKS cluster are deployed using Terraform, the next objective is to deploy a stateful workload (MySQL) inside Kubernetes.
Stateful workloads require persistent storage so that data is not lost when pods restart.

AWS does not include storage support in EKS by default.
To enable persistent storage using AWS EBS volumes, the cluster needs the EBS CSI Driver.


EBS CSI Driver
Three four things are needed here for pods to have data attached to them
1) module/eks/main.tf  Addon section where
1) CSI Driver          = Makes Kubernetes able to create EBS volumes in AWS      = modules/csi_driver

2) StorageClass (gp3)  = Defines the type of EBS volume to create  = storage/storageclass-gp3.aml
  Defines *which type and lifecycle rules* the EBS volumes should have.
3) Helm MySQL Chart    = Requests storage and uses it              = root/main.tf helm section 
  Creates the PersistentVolumeClaim (PVC), which triggers EBS volume provisioning.

Accesing AWS services from Kubernetes pord is nothing but EKS pod Identity
There isn’t a single Terraform Registry module that wraps the EBS CSI driver setup (IAM role + EKS addon) in one go. A module would add little value.
Modules are tools, not requirements. Use them when they add value; otherwise, use resource blocks directly.

EBS CSI Driver exists for EFS or EBS volumes to talk to EKS and store pod data.
  It handles creation of the EBS module
  Attaches and detaches volumes to worker nodes
  Reataches volumes if pods move to another node
  Preserves data even when pods restart

In Terraform this block installs the ebs driver as a managed EKS addon
This is in modules/eks/main.tf
```
addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {}
    kube-proxy = {}
    vpc-cni = {}
  }
```

Elastic block container is an empty storage ( has not operating system ar anything on it) that acts as a Persisten Volume Storage for the data in the pods. Even if the pods fail, the EBS block si remounted on new pods and reconnects the data.
EBS needs CSI driver to comunicate with the Kubernetes control planet whoch manages PersistentVolume and PersistentVolumeClaim objects and AWS Ebs service which actually creates and manages the block volumes at the cloud level.
AWS does not automatically include storage drivers in your worker nodes — that’s where the EBS CSI driver comes in.

When a pod in EKS requests persistent storage via a PersistentVolumeClaim,
Kubernetes itself doesn’t know how to talk to AWS EBS.
It relies on the EBS CSI driver add-on, which:

Receives the request from Kubernetes (through the CSI interface).

Uses AWS APIs (via IAM permissions) to create or attach an EBS volume to the right EC2 worker node.

Mounts the volume into the pod’s filesystem automatically.

Detaches and reattaches the volume if the pod or node is rescheduled elsewhere — preserving data.


Use this command in the CLI to get the latest version for the CSI Driver in conformity with intended running EKS version:
```
aws eks describe-addon-versions \
  --addon-name aws-ebs-csi-driver \
  --kubernetes-version 1.34 \
  --region eu-central-1
```

root/storage/storageclass-gp3.yaml
kubectl apply -f storage/storageclass-gp3.yaml
kubectl get pvc
kubectl get pv
kubectl get pods

STORAGE CLASS CREATES A KUBERNETES OBJECT not an AWS resource
```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-ebs-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: gp3

```
The PVC does not immediately create the EBS volume. 
Because the StorageClass is configured with `volumeBindingMode: WaitForFirstConsumer`,
the EBS volume is only created after a pod is scheduled that uses this PVC.

Important:
The actual EBS volume is not created until a pod that uses the PVC is scheduled.
This is due to the StorageClass setting: `volumeBindingMode: WaitForFirstConsumer`.

Terraform enables the EBS CSI driver in EKS so the cluster can provision EBS volumes. 
The StorageClass (gp3) defines the type of EBS volume to create. 
The MySQL Helm chart creates a PersistentVolumeClaim (PVC), and the PVC triggers the CSI driver 
to provision and attach a gp3 EBS volume to the MySQL pod.

Mysql database:

This goes in root/main.tf

```
data "aws_eks_cluster_auth" "cluster" {#this asks AWS for a authentication token for the cluster_name
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "mysql" {#this is a helm release for the mysql chart
  name       = "mysql"
  namespace  = "default"

  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mysql"
  version    = ">= 9.0.0"
  
  set {
    name  = "primary.persistence.storageClass"
    value = "gp3"
  }

  set {
    name  = "primary.persistence.size"
    value = "20Gi"
  }

  set {
    name  = "auth.rootPassword"
    value = "SuperStrongPassword123" # change before sharing
  }
}
```

Mysql database will live in a pod next to other pods that use EBS for own pod storage. Practically 

MySQL = a pod

The pod = needs a data directory (/var/lib/mysql)

That directory = is mounted from an EBS volume

EBS = is provisioned automatically through your gp3 StorageClass + CSI driver

Kubernetes needs three things in order to run a misql database in Kubernetes with it's data stored on a AWS ebs disk
StorageClass - What type of disk are we creating 
PVC or Persistent volume claim which is a request 
Mysql Pod which is statefull and uses the disk created. 

```
                 ┌─────────────────────────────┐
                 │         Terraform            │
                 │  Deploys EKS + EBS CSI addon │
                 └───────────────┬─────────────┘
                                 │
                                 │ enables
                                 │
                 ┌───────────────▼────────────────┐
                 │       EBS CSI Driver            │
                 │  (allows Kubernetes to create   │
                 │   and attach AWS EBS volumes)   │
                 └───────────────┬────────────────┘
                                 │
                                 │ referenced by
                                 │
             ┌───────────────────▼───────────────────┐
             │        StorageClass: gp3               │
             │  (defines EBS volume type + behavior)  │
             └───────────────────┬───────────────────┘
                                 │
                                 │ used by
                                 │
                    ┌────────────▼────────────┐
                    │   Helm MySQL Release    │
                    │ (deploys MySQL Pod and  │
                    │  creates PVC request)   │
                    └────────────┬────────────┘
                                 │
                                 │ creates
                                 │ PVC (PersistentVolumeClaim)
                                 │
                    ┌────────────▼────────────┐
                    │   PersistentVolumeClaim │
                    │  ("I need 20Gi storage")│
                    └────────────┬────────────┘
                                 │
                                 │ triggers provisioning via CSI
                                 │
                     ┌───────────▼───────────┐
                     │   EBS Volume (gp3)    │
                     │  Created in AWS       │
                     └───────────┬───────────┘
                                 │ attached to
                                 │
                    ┌────────────▼────────────┐
                    │       MySQL Pod         │
                    │   (/var/lib/mysql data) │
                    └─────────────────────────┘


```

######################################################

S3 State Bucket with versioning ( terraform statefile )

Create a root/backend folder 
State backend configuration belongs to the root, because the root controls the entire state.
Modules must never contain backend blocks — they inherit state context from the root.

First off, after we have terraform validate with success we need to run the boostrap folder first so we can create the S3 state bucket 
cd backend/bootstrap
terraform init
terraform apply
then after creation:
We can now go back to root folder, then:
terraform init -migrate-state




Mysql database ( an internal VPC service ):

Mysql database will live in a pod next to other pods that use EBS for own pod storage. Practically 

MySQL = a pod

The pod = needs a data directory (/var/lib/mysql)

That directory = is mounted from an EBS volume

EBS = is provisioned automatically through your gp3 StorageClass + CSI driver

Kubernetes needs three things in order to run a misql database in Kubernetes with it's data stored on a AWS ebs disk
StorageClass - What type of disk are we creating 
PVC or Persistent volume claim which is a request 
Mysql Pod which is statefull and uses the disk created. 

########################################################


Kubernetes Init containers:
Because in K8s or EKS pod creation order is not guaranteed, init containers come in key points in time to intervene and create a particular creation order.
For example Wordpress if created first, is must wait untill MySql is up and running to write it's first ever running data on it, or first user creation. In this way, a init container is similar to a boostrap in Terraform which at first creation handles a kind of order ( some object waiting for config of another object, or installment etc)+
```
yaml file that handles an init container:

initContainers:
  - name: wait-for-mysql
    image: busybox
    command: ['sh', '-c', 'until nc -z mysql 3306; do sleep 2; done;']

```
This makes WordPress wait until:
the MySQL Pod is running
the MySQL port is open
the MySQL service is reachable

Practically the init conainters are mostly declared with YAML files. In Terraform Registry there is no Init Conainers model
In terraform language we use Terraform Kubernetes Provider that translates the YAML to terraform. 
Init containers belong to Kubernetes. -> Terraform just declares the Kubernetes object.
The Kubernetes API server and kubelet execute the init containers.!!!
Init containers are a Kubernetes concept. Terraform does not have ‘init container blocks’ of its own, but you can define init containers inside Kubernetes resources declared through Terraform.

```
resource "kubernetes_pod" "example" {
  metadata {
    name = "example-pod"
  }

  spec {
    init_container {
      name  = "wait-for-db"
      image = "busybox"
      command = [
        "sh",
        "-c",
        "until nc -z mysql 3306; do echo waiting; sleep 2; done;"
      ]
    }

    container {
      name  = "app"
      image = "wordpress"
    }
  }
}

```

#####################

Kubernetes readiness probe and liveness probes,  startup probe - These are used by kubelet( the pod manager )
Practically I never create probes, I just configure them an K8s via kubelet will decide when it is appropriate to deliver them

Probes live in the Pod specifications under each container.
Each container has ITS OWN three probes ( readiness, startup, liveness )

Readiness probe example: In the case of Ollama, it takes around 1 minute to initialize in the container. In this case we do not want anything to send requests to Ollama. If readyness probes are configured to match the project requirements ( late start for some apps or utilities in some containers) the other containers although have started first and are ready will not be left to send any data do Ollama container

Practically I never create probes(they exists as long as the Pod exists), I just configure them an K8s via kubelet will decide when it is appropriate to deliver them

Kubelet periodically executes:
Startup Probe

Runs first
Disables liveness + readiness
Gives app time to boot
If it fails → kubelet restarts container

Readiness Probe
kubelet checks if container is “ready”
If fails → kubelet marks Pod as NotReady
API server removes Pod from Service endpoints
No traffic is sent to the pod

Liveness Probe
kubelet checks if container is alive
If fails → kubelet kills and restarts the container

How a probe manifest config looks like
```
readinessProbe:
  httpGet:
    path: /api/version
    port: 11434
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 60    # 60 x 5 seconds = 300s max wait

```

Example of a pod with two containers. An app container and a utility pod (sidecar pod). Each with it's own probes

```
spec:
  containers:
    - name: main-app
      readinessProbe: ...
    - name: metrics-sidecar
      livenessProbe: ...


```
```
+---------------------------------------------------------------+
|                            POD                                |
|                      (one IP, one network)                    |
|                                                               |
|   +-----------------------+    +---------------------------+  |
|   |    Container A        |    |      Container B         |  |
|   |  (main application)   |    |     (sidecar, logger,    |  |
|   |                       |    |      proxy, metrics...)  |  |
|   |                       |    |                           |  |
|   |  Ports: 8080          |    |  Ports: 9090              |  |
|   |                       |    |                           |  |
|   |  readinessProbe:      |    |  readinessProbe:          |  |
|   |    GET /ready 8080    |    |    GET /ready 9090        |  |
|   |                       |    |                           |  |
|   |  livenessProbe:       |    |  livenessProbe:           |  |
|   |    GET /health 8080   |    |    GET /health 9090       |  |
|   |                       |    |                           |  |
|   |  startupProbe:        |    |  (optional)               |  |
|   |    GET /startup 8080  |    |                           |  |
|   +-----------------------+    +---------------------------+  |
|                                                               |
+------------------------ PodSpec ------------------------------+

                 |
                 |  (kube-scheduler assigns Pod to a node)
                 v

+---------------------------------------------------------------+
|                           NODE                                |
|                    (Worker Node in EKS)                       |
|                                                               |
|   +-------------------------------------------------------+  |
|   |                      kubelet                          |  |
|   |   (the agent that RUNS and CHECKS everything)         |  |
|   |                                                       |  |
|   |  - Runs init containers (sequentially)                |  |
|   |  - Starts application containers                      |  |
|   |  - Executes startupProbe periodically                 |  |
|   |  - Executes readinessProbe periodically               |  |
|   |  - Executes livenessProbe periodically                |  |
|   |  - Restarts containers if liveness fails              |  |
|   |  - Marks Pod Ready/NotReady based on readinessProbe   |  |
|   |  - Controls traffic flow via Service endpoints        |  |
|   |                                                       |  |
|   +-------------------------------------------------------+  |
|                                                               |
+---------------------------------------------------------------+


```

/bin/sh -c nc-z localhost 8095  - this command is used to see if a port is used ???
httpget path:/health-status
tcpSocket Port: 8095


##############################################################################

Resources and limits ( requests, )

Requests:  ( the minimum guaranteed of resources a container gets in a POD) If the node does not have these resources the Pod and containers do no get scheduled

Practically we are defining here what is the minimum of RAM and CPU that a container needs to actually run.

resources:
  requests:
    cpu: "500m"
    memory: "512Mi"
This means that a conainer needs at least 500Mh to run and minimum of 512Mb of ram to run
If the node does not have this much free, the containers inside the pod will not run 

Limits: The maximum allowed for a container in a Pod to use:

resources:
  limits:
    cpu: "1"
    memory: "1Gi"
If the container uses more than this then it will be killed. 

If a container along other running container dies, kubelet will attempt to restart the container - the Pod does not die with everything in it. 
If all of the containers in the pod die, then the POD will attempt to restart if set to ALWAYS restart

Init containers are differentL
Init containers are unique:

They run before all app containers
They run sequentially
If ANY init container fails → the Pod never starts
Pod status becomes:
Init:CrashLoopBackoff

Why it is designed this way:

Because Pods often use sidecars:
logging sidecar
metrics exporter
envoy/istio sidecar
fluent-bit
git-sync
secrets-sync
cert-refresh sidecar
proxy containers
If a sidecar dies, your main app should keep running.
So Kubernetes keeps the Pod alive and only restarts that container.

CLUSTER SIZE MUST BE ACCORDINGLY ( we need a way to calculate this)

#####################################################################

Namespaces - see what you written earlier about namespaces 

Persisten volumes for example cannot be wrapped by a namespace, they are generaly defined


❗ Important detail

Namespaces are created with the Kubernetes provider in Terraform,
not the AWS provider.

Meaning:

You must first create the EKS cluster

Then configure the Kubernetes provider connection

Then Terraform can create namespaces and workloads

BEST PRACTICE:

Managing namespaces through Terraform is recommended if:

✔ You want GitOps-style infrastructure control
✔ You deploy workloads with Terraform
✔ You need strict namespace consistency
✔ You want namespaces to have labels/annotations tied to infra
✔ You're building a platform design (EKS production workflows)

Do NOT manage namespaces by kubectl AND Terraform at the same time.

Because the namespace must be owned by one system (Terraform state).

TO LEARN limit spaces in namespaces. Assign RAM and CPU per namespace, meaning you can have different allocated resources per Dev, Staging and Prod, meaning that Each Dev, Staging, Prod is a separate namespace

Resource quota for namespaces???


################################################################################

Before reading about ALB itself, we must understand that Kubernetes ( or EKS) has it's own Service Types ( ClusterIP, Nodeport, Loadbalancer) but the Loadbalancer inside k8s is not an AWS load balancer or a network load balancer at all -> they operate inside the cluster .
The real hardware/serice lives in AWS (which uses a controller installed in k8s - AWS Loadbalancer controller to com with EKS)
ALB works on Layer 7 of the OSI and NLB on layer 4 of OSI

Cluster service types:
  ClusterIP: 
    Internal only
    It is set as Default service 
    Virtual IP inside cluster
    Not a real Loadbalancer
  NodePort:
    Opens a port on every worker node
    Not a real Loadbalancer
    Only exposes pods via node ports
  LoadBalancer:
    Special type
    Asks cloud provider to create a load balancer
    in EKS is asks to create a NLB by default


Internet → AWS DNS -> Route53 → ALB (L7 uses HTTP protocol) → Target Groups → Worker Nodes → Pods
Internet → AWS DNS -> Route53 → NLB (L4) → Worker Nodes → Pods

Example workflow:
  There are two enabled Availability Zones, with two targets in Availability Zone A and eight targets in Availability Zone B. Clients send requests, and Amazon Route 53 responds to each request with the IP address of one of the load balancer nodes. Based on the round robin routing algorithm, traffic is distributed such that each load balancer node receives 50% of the traffic from the clients. Each load balancer node distributes its share of the traffic across the registered targets in its scope.


AWS ALB

Usefull to revisit: https://www.youtube.com/watch?v=VFwLffElIgc

In EKS:          #in Normal Kubernetes in EC2 these must be setup along many others like etcd, etc
  IAM Roles for Service Accounts (IRSA) are automatically integrated
  The OIDC provider is already managed
  Worker nodes automatically have AWS networking
  Subnets are already tagged for ALB auto-discovery

  In EKS: prerequisites are mostly auto-configured.
  In self-managed Kubernetes on AWS: we configure OIDC, IRSA, subnet tagging, and Helm manually.


ELB is just the name of the AWS load balancing service family.(ELB or CLB is practically deprecated)

Application Load Balancer functions at the application layer, the seventh layer of the Open Systems Interconnection (OSI) model

The load balancer is a single point of contact with the clients. The load balancer distribuites traffic accross multiple targets such as resources like EC2 or others, in multiple AZ - Increases the availibility of the application.

A listener checks for connection requests from clients using the port and protocol that you configure. Default rule for each listener must be defined. One listener can have a different set of rules that point to a different target group of resources. One target can be registered in two target groups or more

Elastic Load Balancing scales your load balancer as traffic to your application changes over time. Elastic Load Balancing can scale to the vast majority of workloads automatically.

You can configure health checks, which are used to monitor the health of the registered targets so that the load balancer can send requests only to the healthy targets.

ALB liver inside the VPC -> Targer groups must belond to tha same VPC as the ALB -> Must have network reachability in the VPC network -> Routing is independent because it is on Layer 7 - The application layer
What ALB actually has:

  The listener:
    You can configure the listener to forward requests based on the URL in the request. In this way you can structure the application in multiple smaller services and route requests using specific URL.
    The default routing algorithm is round robin, specify something else if you want
  Routing is performed independently for each target group, even when a target is registered with multiple target groups

TARGET GROUPS
How Kubernetes and AWS talk to each other -> AWS LoadBalancer Controller:
  A target group is a list of POD IP's exposed by kubernetes service ( A target group does not have it's own IP - is a list of endpoints!!!)
    [target1_IP:port, target2_IP:port, target3_IP:port, ...]
    Target group IP's always change because pods recreate themselves all the time:
      who updates AWS Target Group membership? 
      The AWS LoadBalancer Controller which lives in Kubernetes makes the updated to Target group:
      AWS LB controller watches for Ingress and Service events in Kubernetes, searches the matching pods via label selectors, register and deregisters POD IP's from TargetGroups
      Reconciles continuously Desired state vs Current state -> This is a state sync loop. ( the loop has no interval, Inside Kubernetes, controllers subscribe to API change streams: any service added, updated, scaled, rescheduled, pod IP changed, intress created/updated = event that the loops reads - controller receives and it reacts - Inside Kubernetes, controllers subscribe to API change streams) Every 10 minutes there is a default general sync anyway
      Kubernetes does not tell ALB how many pods exist. 
      
      A target group contains
        a list of targets
        a health chech definition for the list of targets
        protocol and port settings


TARGET Types ( different to target groups ):

Before we understand target types we need to understand Kubernetes services
  ClusterIP ( mapped to IP )
  And Instance ( mapped to Node port)
  


The configuration of what is in the target groups - meaning the targets themselves
```
The bellow is an explanation of K8s service possibilites
https://docs.aws.amazon.com/eks/latest/best-practices/vpc-cni.html
ALB target type set to "instance" 
  ALB sends traffic to nodes -> nodes expose NodePorts -> Service must be set to Nodeport

  You always reach PODs though the node network stack but 
  Choosing ClusterIP (ip) does not mean bypassing the whole Node - Traffic always goes through the node.
  HOW traffic actually gets there is established by one of the two possibilites:
    ClusterIP or Nodeport
NodePort (Instance): (ALB registers node IP's)
  Packet arrives at node ENI
    Kubeproxy listens on NodePort
      forwards to POD
ClusterIP (IP) (the most used)
  Packet arrives at node ENI ( Elastic Network Interface)
    AWS VPC CNI routes directly to pod IP (uses pod IP's from Endpoints)
      POD receives traffic

      No NodePort needed, works in Fargate, ALB registers pod IP's?, uses Pod ip's from Endpoints

    Cluster IP is a service abstraction, a way for kubernetes to track pod Endpoints
      ClusterIP creates Endpoints of the POD's like this:
      10.123.4.21:8080
      10.123.7.44:8080
      10.123.9.88:8080
    AWS LB Controller reads the ClusterIP list and registers the POD in ALB target group

    The ALB can route to POD IP's because of AWS VPC CNI ( container network interface)
      Pod lives behind Node ENI
      Pod IP is routable inside VPC
      Node network stack routes packet to pod

      No kubeproxy, no NodePort listener, ALB can target the pod IP's

ALB->
 → Node ENI
   → VPC CNI routing
     → Pod IP
Why is it better to use ClusterIP
Required for Fargate
Better autoscaling
No NodePort range exhaustion
No cross-AZ traffic penalties
Cleaner security boundaries
ALB health checks hit pods, not nodes
!!!AWS VPC CNI is responsible for connecting pods to ALB directly through a list of pod IPs created into the ALB.!!!

```

ALB target type set to "IP" (just like in our project)
  ALB sends traffic directly to POD IP's -> Service should be set to ClusterIP
  Nodeport is not needed
  When target type is IP, you can specify IP adresses from one of the vpc the CIDR blocks

ALB target type set to "lambda" -> 

```
| ALB Target Mode | Service Type Required | Why                       |
| --------------- | --------------------- | ------------------------- |
| **instance**    | NodePort              | ALB targets nodes         |
| **ip**          | ClusterIP             | ALB targets pods directly |

```

Rules to follow
- ALB ingress creates AWS ALB ( ingress is just a set of rules of K8s)
- Controller watches Kubernetes ingress
- ALB routes traffic to either:
   nodeports (instance mode)
   pod IPs (ip mode)
- API server is only for cluster management
- NAT is only for outbound internet
- Nodes and pods live in private subnets
- ALB lives in public subnets

  ALB (Static URL/public) -> Listerner rule -> Target groups ( the list of endpoints) -> POD running and exposed by service

ALB  = HTTP/HTTPS apps (WordPress, APIs, websites)
NLB  = TCP/UDP, high performance, internal services
GWLB = Network security appliance traffic routing

Main possibilites for ALB:
-  Path conditions: You can configure rules for your listener that forward requests based on the URL in the request. This enables you to structure your application as smaller services, and route requests to the correct service based on the content of the URL.

- Routing based on fields in the request, such as HTTP header conditions and methods, query parameters, and source IP addresses
- Routing requests to multiple applications on a single EC2 instance. You can register an instance or IP address with multiple target groups, each on a different port.
- Redirecting requests from one URL to another.
- Returning a custom HTTP response.
- Registering targets by IP address, including targets outside the VPC for the load balance
- Registering targets by IP address, including targets outside the VPC for the load balance
- Load balancer to authenticate users of your applications through their corporate or social identities before routing requests
- Containerized applications. Amazon Elastic Container Service (Amazon ECS) can select an unused port when scheduling a task and register the task with a target group using this port. This enables you to make efficient use of your clusters
- Monitoring the health of each service independently, as health checks are defined at the target group level and many CloudWatch metrics are reported at the target group level. Attaching a target group to an Auto Scaling group enables you to scale each service dynamically based on demand
- Access logs contain additional information and are stored in compressed format



In a Terraform module the steps are look like this
It must have the following installed :
  OIDC created
  IRSA (IAM role for service accounts)
  Subnets that are autotriggered
  Node IAM roles are setup properly
  After those are setup, ALB controller becomes just a resource in TF ( helm release )
  resource "helm_release" "aws_load_balancer_controller" { ... }

AWS LB controller install policy with helm ( it needs it in the module/alb_irsa/iam-policy.jason ) - https://github.com/kubernetes-sigs/aws-load-balancer-controller/blob/main/docs/install/iam_policy.json
AWS Load Balancer Controller:
 Runs inside Kubernetes, not AWS.
 Not built into EKS, but maintained by AWS.
 Works on any Kubernetes cluster running in AWS.
 Does NOT work outside AWS.

 AWS Load Balancer Controller = Event-driven.
Watches Ingress + Service + EndpointSlice.
Updates target group membership in real-time.
No polling interval. Safety resync ~10 min.

With Application Load Balancer at cross zone level, it is always activated. Cross zone target groups can be deactivated
For NLB ( network load balancer) and Gateway balancers, the cross zone is always disabled by default but can be activated.

Zonal Shift is an Amazon application recovery controller (ARC) capability that let's you move the ALB from a affected AZ to another functional one
https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/how-elastic-load-balancing-works.html

The AWS Load Balancer Controller is not built into EKS.
It must be installed manually on all Kubernetes clusters including in EKS

For FARGATE ingress controller does not exist because you do no see the nodes ( you have no nodes to authenticate to AWS)
When you install the AWS Load Balancer Controller in a Kubernetes cluster, it will create AWS resources only when you create Ingress or Service objects that require them.
  The controller itself does NOT create AWS resources.
  When you create certain Kubernetes objects (like Ingress or Service of type LoadBalancer), the AWS Load Balancer Controller reacts and creates the necessary AWS resources (ALB, target groups, listeners, security groups, etc.). It watches ingres through API server of the K8 cluster

The Service object is in Kubernetes.
  The Load Balancer resource is in AWS.
  You define the intent inside the cluster → cloud provider fulfills it outside.
  This is why the documentation always says:
    Service type LoadBalancer asks the cloud provider to create an external Load Balancer.



Mental model of AWS execution untill ALB is finished

```
(1) VPC + Subnets (with correct AWS ALB tags)
       ↑
(2) EKS Cluster created inside VPC
       ↑
(3) ALB Controller installed (Helm chart)
       ↑
(4) You create an Ingress
       ↑
(5) ALB Controller reads subnet tags

```
INGRESS
```
Ingress = Routing Rules
Controller = Behavior
AWS = Creates ALB Only If ALB controller is installed
EKS = Creates NLB Only If Service type=LoadBalancer
```
Ingress is just a set of roting rules in Kubernetes (EKS)
The ingress controller you install interprets the Ingress rules in Kubernetes

  Ingress = just routing rules
  ALB Controller = interprets ingress → creates ALB

```
| Resource                      | What it is         | Who creates LB               | LB Type     |
| ----------------------------- | ------------------ | ---------------------------- | ----------- |
| **Ingress object**            | just routing rules | NONE by itself               | NONE        |
| **Ingress + ALB Controller**  | L7 routing + ALB   | AWS LB Controller            | **ALB**     |
| **Service type=LoadBalancer** | L4 LB request      | AWS Cloud Controller Manager | **NLB**     |
| **Nginx Ingress**             | internal proxy     | no AWS LB                    | Nginx pod   |
| **Traefik Ingress**           | internal proxy     | no AWS LB                    | Traefik pod |






%%% Steps to actually configure and deploy ALB after S3State,VPC,EKS,EBS are deployed and configured %%%

Installing the AWS Load Balancer controller

Tag the subnets in VPC module
subnets used in the VPC need tag namings in order to be recognized and used by the ALB
These tags are in conformity with AWS documentation here - https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html

```
  public_subnet_tags = {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
```




WP local testing
When this works locally → your environment variables and connectivity are correct.

When deploying to Kubernetes, you'll translate the same values to:

values.yaml for WordPress Helm chart

Kubernetes Secret for DB password

Service + Ingress for access

PVC for data storage


######################################################






&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
TO DO NEXT: # this will vary from day to day 

Check cursor for the last indications on CSI module
0. terraform apply                 # create EKS + CSI
aws eks update-kubeconfig
kubectl apply storageclass-gp3
terraform apply                 # MySQL deploy
helm install wordpress ...      # or helm_release
kubectl apply ingress.yaml      # triggers ALB

0. Add a Readme.de with project purpose and tech used. Who runs who
1. continue in with S3's and their endpoints???. THe s3's must be checked with TF registry and then declared correctly inside vcp_endpoints. What reouting tables are we allocating???
2. Link data to Ollama ( instructions in learning doc)\
3. Some diagram featuring EBS CSI -> storageclass -> PVC
  ALB controller -> Ingress flow



Bonus : play in "kind" with PV, PVC, Mysql, etc
Generate a YAML file of a certain image (Dry run is the best way to generate a skeleton, which can then be modified as per the requirements) 
‘kubectl create deployment [deployment-name] --image=[image-name] -n [namespace] --dry-run=client -o yaml > d.yaml’



Kubernetes secrets?


To asess if needed!: 
No RDS MySQL infrastructure
No Kubernetes manifests for WordPress
No Kubernetes manifests for MySQL (if deploying in-cluster)
No Ingress/ALB controller setup
No PersistentVolumeClaims for WordPress media
No Secrets for database credentials
No ConfigMaps for WordPress configuration


REMINDERS: # these lines constantly change also in relation to project evolutiuon


EC2 in private subnet needs → NAT Gateway or VPC Endpoint.

RDS needs → Security Group that allows DB port from app layer (EC2/EKS).

Terraform backend needs → S3 + DynamoDB.

Private communication between AWS services needs → Interface Endpoints.

Public access (e.g., website) needs → ALB in public subnet.



&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&








