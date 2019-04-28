# Kubernetes Cluster installation

## Overview
For the kubernets cluster, this is just a test for the configuration, not production ready. For production readiness I would have the master nodes spread across availability zones, having different autoscaling groups for each one.

For the time constraint of this excercise I took a couple of design licenses concerning where I run the kubernets cluster and infrastructure design. The infrastructure is not exactly designed for failure as any production application should, like holding the kubernets master metadata across separated masters, the terraform metadata for the control instance, etc.

To make easier to replicate the kubectl and kops control instance, there is a terraform template in the repository that will create the instance with all the requirements from the [kops installation doc][2].

The steps that are detailed in this file are as follows:
1. Launch a control instance that will have kubectl, kops, helm.
2. Optionally the terraform template can create the necessary hosted zone, s3 bucket and permissions in the account that are necessary.
3. The necessary steps to launch a basic kubernets cluster using this control instance, this will create separatedly the kubernets vpc, autoscalling groups, instances, security groups, etc.
4. Launch Jenkins within the kubernets cluster using helm.
5. Launch a Python application in the kubernets cluster, I'll use a separated repository for the python app.
6. Configure Jenkins to automate the Python application deployments.

## Pre-requisites
In order to launch the control instance, will be necessary to have an AWS account.

### Generate SSH key
It's necessary to generate a ssh key pair to be used to access the control instance and later on from the control instance to the kubernets cluster.
```
$ ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_kube -C "Kube control isntance and cluster"
```
That should generate two files
```
~/.ssh/id_rsa_kube
~/.ssh/id_rsa_kube.pub
```

### AWS IAM Account
It's necessary to have an AWS account with admin privileges and generate a AWS key pair.

'''For improvement: detail the minimum required permissions'''

### AWS CLI
The minimum necessary to run the steps bellow is just having the credentials file with the aws cli credentials format accessible by terraform, but I configured the AWS CLI to test access and permissions in the account.

#### AWs Cli on MacOS
* Install AWS CLI (asumming you already have [homebrew][6] configured):
	$ brew install awscli
* Configure AWS Credentials. With the credentials generated in the section [AWS IAM Account](#aws-iam-account)
  Add the credentials into your home directory
	```
	mkdir -p ~/.aws
	vim ~/.aws/credentials
	```
	  Add the credentials with the following format, where "default" in this case is the aws cli profile, I only have one for this machine.
	```
	[default]
	aws_access_key_id =  ********************
	aws_secret_access_key = ****************************************
	```
* Testing the AWS CLI
```
$ aws ec2 describe-instances --region eu-west-1 --output json > /dev/null
$ echo $?
0
```
#### AWs Cli on GNU/Linux
	* TBD
#### AWs Cli on Windows
	* TBD

### Terraform binary
Terraform is not more than a statically compiled binary, the deployment is simple. Just having "terraform" in path woudl be enough. I'll install [Terraform][4] in my laptop, currently using MacOS, but there are options for other operating systems.

#### Terraform binary on MacOS
	+ Download [Terraform binary][5].
	+ Extract the binary and deploy to a system path to be used.
	```
	$ unzip terraform_0.11.13_darwin_amd64.zip
	Archive:  terraform_0.11.13_darwin_amd64.zip
	  inflating: terraform
	$ mkdir -p ~/bin                                                                       
	$ mv -v terraform ~/bin
	terraform -> /Users/dbandin/bin/terraform
	$ export PATH=$PATH:~/bin
	$ echo $PATH
	/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/Users/dbandin/bin
	$ terraform --version
	Terraform v0.11.13
	$ echo "export PATH=$PATH:~/bin" >> ~/.zshrc
	```

#### Terraform binary on GNU/Linux
- TBD

#### Terraform binary on Windows
- TBD

## Launch the Control instance
The Control instance with the necessary permissions and software will be launch with terraform, it may be a little redundant using terraform and then kubernets on top, but I wanted to have an easy way to replicate the instance with the necessary configurations and software. This could had been done directly with CloudFormation, but starting it with terraform should make it easier to move to another cloud providers.

'''to-do: The terraform template have still a lot of room for improvement, making it modular and accepting parameters for things like region, ami, availability zone, ip ranges, etc.'''

### Launching the terraform template
The tempalte also creates a VPC, subnet, internet gateway and other requirements to hold the instance assuming you have nothing in the region, also to avoid adding manual steps into the creation and logic into the templates due to the time constraint.

We'll be using the terraform template [control_instance.tf](terraform_templates/control_instance.tf) in this repository.

Before starting, this repository [kubernets-config-and-doc][7] should be cloned in the computer where the pre-requisite steps took place (where the aws cli and terraform binary are configured). In the bellow steps I assumed that the repository is clonned in the directory path "~/repositories/".

- step into the repository directory with the terraform template.
```
$ pwd
~/repositories/kubernetes-config-and-doc/terraform_templates
```
- Run terraform plan to see the resources to be created.
```
$ terraform plan
```
- If everything looks good in the plan output, create the stack
```
$ terraform apply
...
Outputs:

instance-id = i-00123456790abcdef
instance-public-ip = 54.111.111.111
key-id = KubeControlKey
vpc-id = vpc-00123456790abcdef
vpc-publicsubnet = 192.168.0.0/24
vpc-publicsubnet-id = subnet-00123456790abcdef
```
- Test the connection to the instance
```
$ ssh -i ~/.ssh/id_rsa_kube -l ec2-user 54.111.111.111
```

Ok, we have the instance running with the tools to start playing with kubernets.

## kubectl and kops
These two binaries are installed already in the instance when it's launched using the "user-data" metadata to run commands on startup of the instance. The desicion to use [kops][0] is regarding the available tools and time at the moment.

Sadly, couldn't install kubectl using the yum/rpm option because there is a bug with the rpm signature google files authenticating into Amazon Linux. There is a [kubectl bug](https://github.com/kubernetes/kubernetes/issues/60134) open without much activity, so I decided to install the statically compiled binary.

'''note: kubectl and kops are added to the user_data of the control instance in the terraform template, it's not necessary to intervene manually.'''

Seems like [kubeadm][1] could be a good option to research for a production cluster.

## Creating a kubernetes cluster
Here is where the kluster will be created. You can refer to [Kubernetes kops documentation][2] for more information.

'''The following commands will be run in the control instance'''

### Create the config
This command will create the configuration for the cluster. The other commands that actually modify the infrastructure may ask you to run the same command with the argument "--yes" that will make the actual changes, by default kops commands run in a sort of preview or dry-run mode and using "--yes" makes them effective in the infrastructure.

'''Note: There is something needs to be handled in this document or automation. I'm using the same .pub key that I generated with the [SSH Key](#generate-ssh-key) step, for next iteration I'll use forwarding or the generation of another key in the control instance itself, the private key shouldn't be posted for security reasons.'''

```
$ kops create cluster --zones=eu-west-1b clusters.db.transfinity.systems
... SOME OUTPUT ...

Must specify --yes to apply changes

Cluster configuration has been created.

Suggestions:
 * list clusters with: kops get cluster
 * edit this cluster with: kops edit cluster clusters.db.transfinity.systems
 * edit your node instance group: kops edit ig --name=clusters.db.transfinity.systems nodes
 * edit your master instance group: kops edit ig --name=clusters.db.transfinity.systems master-eu-west-1b

Finally configure your cluster with: kops update cluster clusters.db.transfinity.systems --yes
```

Checking that the config is present.
```
[ec2-user@ip-192-168-0-61 ~]$ kops get cluster
NAME				CLOUD	ZONES
clusters.db.transfinity.systems	aws	eu-west-1b
```

To edit the cluster config to modify the instance type in example, the following command could be used, I'll change the default instance type to t2.small.
```
$ kops edit ig --name=clusters.db.transfinity.systems nodes
```

### Launch the cluster
The previous steps only created the cluster metadata and uploaded to the s3 bucket kops require. Now we can create the cluster with that metadata using the "update cluster" command.
```
$ kops update cluster clusters.db.transfinity.systems
```
After looking at all the resources that will be created/modified we can run the command with "--yes". this same command could be used if we modify the cluster configuration for instance type, numbers, etc.
```
$ kops update cluster clusters.db.transfinity.systems --yes
I0428 12:18:14.783040    3732 executor.go:103] Tasks: 0 done / 73 total; 31 can run
I0428 12:18:15.288567    3732 vfs_castore.go:735] Issuing new certificate: "apiserver-aggregator-ca"
I0428 12:18:15.326101    3732 vfs_castore.go:735] Issuing new certificate: "ca"
I0428 12:18:15.601284    3732 executor.go:103] Tasks: 31 done / 73 total; 24 can run
I0428 12:18:16.629216    3732 vfs_castore.go:735] Issuing new certificate: "apiserver-proxy-client"
I0428 12:18:17.432418    3732 vfs_castore.go:735] Issuing new certificate: "kubelet"
I0428 12:18:18.113548    3732 vfs_castore.go:735] Issuing new certificate: "master"
I0428 12:18:18.182540    3732 vfs_castore.go:735] Issuing new certificate: "kubecfg"
I0428 12:18:18.665897    3732 vfs_castore.go:735] Issuing new certificate: "kops"
I0428 12:18:18.833859    3732 vfs_castore.go:735] Issuing new certificate: "apiserver-aggregator"
I0428 12:18:18.884761    3732 vfs_castore.go:735] Issuing new certificate: "kube-controller-manager"
I0428 12:18:19.083898    3732 vfs_castore.go:735] Issuing new certificate: "kube-proxy"
I0428 12:18:19.226886    3732 vfs_castore.go:735] Issuing new certificate: "kube-scheduler"
I0428 12:18:19.256108    3732 vfs_castore.go:735] Issuing new certificate: "kubelet-api"
I0428 12:18:19.512687    3732 executor.go:103] Tasks: 55 done / 73 total; 16 can run
I0428 12:18:19.707858    3732 launchconfiguration.go:380] waiting for IAM instance profile "nodes.clusters.db.transfinity.systems" to be ready
I0428 12:18:19.712100    3732 launchconfiguration.go:380] waiting for IAM instance profile "masters.clusters.db.transfinity.systems" to be ready
I0428 12:18:30.143858    3732 executor.go:103] Tasks: 71 done / 73 total; 2 can run
I0428 12:18:30.698502    3732 executor.go:103] Tasks: 73 done / 73 total; 0 can run
I0428 12:18:30.698611    3732 dns.go:153] Pre-creating DNS records
I0428 12:18:31.300865    3732 update_cluster.go:290] Exporting kubecfg for cluster
kops has set your kubectl context to clusters.db.transfinity.systems

Cluster is starting.  It should be ready in a few minutes.

Suggestions:
 * validate cluster: kops validate cluster
 * list nodes: kubectl get nodes --show-labels
 * ssh to the master: ssh -i ~/.ssh/id_rsa admin@api.clusters.db.transfinity.systems
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/addons.md.
```

At this point, the best will be giving 5/10 minutes to the cluster to come up and settle.

'''coffee break'''

![This is Fine](img/thisisfine.jpeg)


Validate the cluster and check with kubectl if it's running. "kops validate" will show you the cluster from the AWS perspective, instance-wise.
```
$ kops validate cluster
Using cluster from kubectl context: clusters.db.transfinity.systems

Validating cluster clusters.db.transfinity.systems

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
master-eu-west-1b	Master	m3.medium	1	1	eu-west-1b
nodes			Node	t2.small	2	2	eu-west-1b

NODE STATUS
NAME						ROLE	READY
ip-172-20-37-140.eu-west-1.compute.internal	node	True
ip-172-20-61-136.eu-west-1.compute.internal	master	True
ip-172-20-62-58.eu-west-1.compute.internal	node	True

Your cluster clusters.db.transfinity.systems is ready
```
Then you can check the actual kubernetes nodes with kubectl.
```
$ kubectl get nodes -o wide
NAME                                          STATUS   ROLES    AGE   VERSION    EXTERNAL-IP     OS-IMAGE                      KERNEL-VERSION   CONTAINER-RUNTIME
ip-172-20-37-140.eu-west-1.compute.internal   Ready    node     2m    v1.10.13   34.244.29.112   Debian GNU/Linux 8 (jessie)   4.4.148-k8s      docker://17.3.2
ip-172-20-61-136.eu-west-1.compute.internal   Ready    master   4m    v1.10.13   34.246.134.37   Debian GNU/Linux 8 (jessie)   4.4.148-k8s      docker://17.3.2
ip-172-20-62-58.eu-west-1.compute.internal    Ready    node     3m    v1.10.13   52.50.174.244   Debian GNU/Linux 8 (jessie)   4.4.148-k8s      docker://17.3.2
```

### Running Tiller
The tiller definition is already in the instance, it was populated by the "user-data" into the file "/home/ec2-user/tiller-rbac.yaml". With kubectl we can apply the tiller definition.

Apply the tiller configuration with kubectl.
```
$ kubectl apply -f tiller-rbac.yaml
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller-clusterrolebinding created
```
Check the tiller service account.
```
$ kubectl get serviceaccount --all-namespaces
...
kube-system   tiller                               1         2m
...
$ kubectl get clusterrolebinding
...
tiller-clusterrolebinding                              3m12s
```

We should be able to initialize tiller with helm now.
```
$ helm init --service-account tiller --upgrade
Creating /home/ec2-user/.helm
Creating /home/ec2-user/.helm/repository
Creating /home/ec2-user/.helm/repository/cache
Creating /home/ec2-user/.helm/repository/local
Creating /home/ec2-user/.helm/plugins
Creating /home/ec2-user/.helm/starters
Creating /home/ec2-user/.helm/cache/archive
Creating /home/ec2-user/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /home/ec2-user/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
```

Verify the tiller pod
```
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                                  READY   STATUS    RESTARTS   AGE
kube-system   dns-controller-66c9d7d5df-gx7sx                                       1/1     Running   0          16m
kube-system   etcd-server-events-ip-172-20-61-136.eu-west-1.compute.internal        1/1     Running   0          15m
kube-system   etcd-server-ip-172-20-61-136.eu-west-1.compute.internal               1/1     Running   0          15m
kube-system   kube-apiserver-ip-172-20-61-136.eu-west-1.compute.internal            1/1     Running   0          15m
kube-system   kube-controller-manager-ip-172-20-61-136.eu-west-1.compute.internal   1/1     Running   0          16m
kube-system   kube-dns-5fbcb4d67b-7gqwm                                             3/3     Running   0          14m
kube-system   kube-dns-5fbcb4d67b-s99cc                                             3/3     Running   0          14m
kube-system   kube-dns-autoscaler-6874c546dd-fxbp5                                  1/1     Running   0          16m
kube-system   kube-proxy-ip-172-20-37-140.eu-west-1.compute.internal                1/1     Running   0          14m
kube-system   kube-proxy-ip-172-20-61-136.eu-west-1.compute.internal                1/1     Running   0          16m
kube-system   kube-proxy-ip-172-20-62-58.eu-west-1.compute.internal                 1/1     Running   0          13m
kube-system   kube-scheduler-ip-172-20-61-136.eu-west-1.compute.internal            1/1     Running   0          16m
kube-system   tiller-deploy-75f9fbff5d-sgfvb                                        1/1     Running   0          31s
```

Few other helpfull commands to use:
```
kubectl logs -n kube-system <tiller-pod>
```

### Launch Jenkins
Jenkins will be installed with helm. So, tiller should already be running in the cluster at this point.

Firstly update the chart repository.
```
$  helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈
```
We can lookup now in the repository for jenkins.
```
$ helm search jenkins
NAME          	CHART VERSION	APP VERSION	DESCRIPTION
stable/jenkins	1.1.10       	lts        	Open source continuous integration server. It supports mu...
$ helm fetch stable/jenkins
$ ls
jenkins-1.1.10.tgz  tiller-rbac.yaml
$ tar -xvzf jenkins-1.1.10.tgz
```
The above commands searched for jenkins, fetched the tar file with definitions and we can see the ".tgz" file in the current directory.

Now, Jenkins can be installed with helm
```
$ helm install  --name jenkins --namespace jenkins -f ~/jenkins/values.yaml --version 1.1.10 stable/jenkins
NAME:   jenkins
LAST DEPLOYED: Sun Apr 28 13:14:29 2019
NAMESPACE: jenkins
STATUS: DEPLOYED

RESOURCES:
==> v1/ConfigMap
NAME           DATA  AGE
jenkins        5     0s
jenkins-tests  1     0s

==> v1/Deployment
NAME     READY  UP-TO-DATE  AVAILABLE  AGE
jenkins  0/1    1           0          0s

==> v1/PersistentVolumeClaim
NAME     STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
jenkins  Pending  gp2     0s

==> v1/Pod(related)
NAME                     READY  STATUS   RESTARTS  AGE
jenkins-cbbfcfdbf-rzzvk  0/1    Pending  0         0s

==> v1/Role
NAME                     AGE
jenkins-schedule-agents  0s

==> v1/RoleBinding
NAME                     AGE
jenkins-schedule-agents  0s

==> v1/Secret
NAME     TYPE    DATA  AGE
jenkins  Opaque  2     0s

==> v1/Service
NAME           TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S)         AGE
jenkins        LoadBalancer  100.65.129.224  <pending>    8080:30009/TCP  0s
jenkins-agent  ClusterIP     100.64.200.186  <none>       50000/TCP       0s

==> v1/ServiceAccount
NAME     SECRETS  AGE
jenkins  1        0s


NOTES:
1. Get your 'admin' user password by running:
  printf $(kubectl get secret --namespace jenkins jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace jenkins -w jenkins'
  export SERVICE_IP=$(kubectl get svc --namespace jenkins jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
  echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin


For more information on running Jenkins on Kubernetes, visit:
https://cloud.google.com/solutions/jenkins-on-container-engine
```

Few commands to get info
```
$ kubectl get all --all-namespaces
$ kubectl describe pod -n jenkins <jenkins-pod>
```

## TO-DO
- Add configuration for hosted zones in the terraform template.
- Improve user-data. Too many hardcoded urls and values. But it's simple right now.
- Improve terraform template for modularity and parameters.
- Evaluate the use of kubeadm over kops.
- List tiller config source in the links.


[0]: https://github.com/kubernetes/kops "Kops Repository"
[1]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/ "kubeadm Documentation"
[2]: https://kubernetes.io/docs/setup/custom-cloud/kops/ "Kubernetes kops documentation"
[3]: https://kubernetes.io/docs/tasks/tools/install-kubectl/ "kubectl installation"
[4]: https://www.terraform.io/ "Terraform"
[5]: https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_darwin_amd64.zip "Terraform Binary"
[6]: https://brew.sh/ "Hombre Official page"
[7]: https://github.com/dbandin/kubernetes-config-and-doc "This repo"