# Kubernetes Cluster

## Install Kubernetes Cluster.
I'm following the kubernets documentation to set up a basic cluster in AWS using [kops][0], being that I have this tools by hand and due to the time constraint. Having more time I would check for [kubeadm][1].

- Documentation: [Kubernetes kops documentation][2]

### Pre-requisites
- AWS Cli installed and configured with admin credentials in the host you'll be running terraform.
	+ MacOS:
		* Install AWS CLI (asumming you already have homebrew configured):
			$ brew install awscli
		* Configure AWS Credentials
			- Create IAM User with admin privileges.
			- Generate a credential pair for the user.
				+ Add the credentials into your home directory
					* mkdir -p ~/.aws
					* vim ~/.aws/credentials

					```
					[default]
					aws_access_key_id =  ********************
					aws_secret_access_key = ****************************************
					```
	+ Testing the AWS CLI
	```
	$ aws ec2 describe-instances --region eu-west-1 --output json > /dev/null
	$ echo $?
	0
	```
- Install terraform binary. As pre-requisite, I'll install [Terraform][4] in my laptop, currently using MacOS, but there are options for other operating systems.
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


### Creating a cluster
The first section of the documentation points that requires [kubectl][3] for kops to work, I'll create and AWS instance with kubectl to avoid problems with connectivity.

#### Create the control instance for kubectl
Need first to create a VPC (Virtual Network) to hold the cluster and control instance. The control instance could be inside or outside the VPC, I'll make it inside, so, it's easier to replicate the provisioning and tools installation.

Using the terraform template in this repository [kubernetes_vpc.tf](terraform_templates/kubernetes_vpc.tf) we can create a vpc with public access and an instance in it to deploy kubectl later.

##### Steps to create control instance
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
$ ssh -i ~/.ssh/DiegoTest.pem -l ec2-user 54.111.111.111
```

#### Install kubectl
Following the [kubectl installation][3] on Linux will deploy it to an AWS instance.

Once Logged in to the control instance created in the previous step, you can download and install kubectl.

Sadly, it cannot be installed used the yum/rpm option because the signature google files are not working and doesn't seem to have any activity from the maintainers. [kubectl bug](https://github.com/kubernetes/kubernetes/issues/60134)

kubectl and kops are added to the user_data of the control instance in the terraform template, it's not necessary to intervene manually.


#### Cluster config
kops create cluster --zones=eu-west-1b clusters.db.transfinity.systems

```
$ kops create cluster --zones=eu-west-1b clusters.db.transfinity.systems
I0427 20:55:25.774082    3429 create_cluster.go:480] Inferred --cloud=aws from zone "eu-west-1b"
I0427 20:55:25.825902    3429 subnets.go:184] Assigned CIDR 172.20.32.0/19 to subnet eu-west-1b
Previewing changes that will be made:


SSH public key must be specified when running with AWS (create with `kops create secret --name clusters.db.transfinity.systems sshpublickey admin -i ~/.ssh/id_rsa.pub`)
$ kops create secret --name clusters.db.transfinity.systems sshpublickey admin -i ~/.ssh/id_rsa.pub
$ kops get cluster
NAME				CLOUD	ZONES
clusters.db.transfinity.systems	aws	eu-west-1b
$ kops edit ig --name=clusters.db.transfinity.systems nodes
Edit cancelled, no changes made.
$ kops update cluster clusters.db.transfinity.systems --yes
I0427 21:01:44.118768    3504 executor.go:103] Tasks: 0 done / 73 total; 31 can run
I0427 21:01:44.741098    3504 vfs_castore.go:735] Issuing new certificate: "apiserver-aggregator-ca"
I0427 21:01:44.768850    3504 vfs_castore.go:735] Issuing new certificate: "ca"
I0427 21:01:45.114050    3504 executor.go:103] Tasks: 31 done / 73 total; 24 can run
I0427 21:01:47.420251    3504 vfs_castore.go:735] Issuing new certificate: "kops"
I0427 21:01:47.728198    3504 vfs_castore.go:735] Issuing new certificate: "kubelet-api"
I0427 21:01:47.811080    3504 vfs_castore.go:735] Issuing new certificate: "kube-scheduler"
I0427 21:01:47.864058    3504 vfs_castore.go:735] Issuing new certificate: "kube-proxy"
I0427 21:01:48.537338    3504 vfs_castore.go:735] Issuing new certificate: "apiserver-proxy-client"
I0427 21:01:48.676976    3504 vfs_castore.go:735] Issuing new certificate: "kube-controller-manager"
I0427 21:01:48.747162    3504 vfs_castore.go:735] Issuing new certificate: "kubecfg"
I0427 21:01:48.958446    3504 vfs_castore.go:735] Issuing new certificate: "apiserver-aggregator"
I0427 21:01:48.970034    3504 vfs_castore.go:735] Issuing new certificate: "kubelet"
I0427 21:01:49.106528    3504 vfs_castore.go:735] Issuing new certificate: "master"
I0427 21:01:49.308918    3504 executor.go:103] Tasks: 55 done / 73 total; 16 can run
I0427 21:01:49.508016    3504 launchconfiguration.go:380] waiting for IAM instance profile "nodes.clusters.db.transfinity.systems" to be ready
I0427 21:01:49.534249    3504 launchconfiguration.go:380] waiting for IAM instance profile "masters.clusters.db.transfinity.systems" to be ready
I0427 21:02:00.000165    3504 executor.go:103] Tasks: 71 done / 73 total; 2 can run
I0427 21:02:01.148639    3504 executor.go:103] Tasks: 73 done / 73 total; 0 can run
I0427 21:02:01.148744    3504 dns.go:153] Pre-creating DNS records
I0427 21:02:01.753599    3504 update_cluster.go:290] Exporting kubecfg for cluster
kops has set your kubectl context to clusters.db.transfinity.systems

Cluster is starting.  It should be ready in a few minutes.

Suggestions:
 * validate cluster: kops validate cluster
 * list nodes: kubectl get nodes --show-labels
 * ssh to the master: ssh -i ~/.ssh/id_rsa admin@api.clusters.db.transfinity.systems
 * the admin user is specific to Debian. If not using Debian please use the appropriate user based on your OS.
 * read about installing addons at: https://github.com/kubernetes/kops/blob/master/docs/addons.md.

```


[0]: https://github.com/kubernetes/kops "Kops Repository"
[1]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/ "kubeadm Documentation"
[2]: https://kubernetes.io/docs/setup/custom-cloud/kops/ "Kubernetes kops documentation"
[3]: https://kubernetes.io/docs/tasks/tools/install-kubectl/ "kubectl installation"
[4]: https://www.terraform.io/ "Terraform"
[5]: https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_darwin_amd64.zip "Terraform Binary"