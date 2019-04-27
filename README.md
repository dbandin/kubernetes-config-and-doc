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
	$ mkdir -p ~/bin                                                                       $ mv -v terraform ~/bin
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

[0]: https://github.com/kubernetes/kops "Kops Repository"
[1]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/ "kubeadm Documentation"
[2]: https://kubernetes.io/docs/setup/custom-cloud/kops/ "Kubernetes kops documentation"
[3]: https://kubernetes.io/docs/tasks/tools/install-kubectl/ "kubectl installation"
[4]: https://www.terraform.io/ "Terraform"
[5]: https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_darwin_amd64.zip "Terraform Binary"