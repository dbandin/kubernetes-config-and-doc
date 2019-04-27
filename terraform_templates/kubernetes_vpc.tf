provider "aws" {
  region = "eu-west-1"
  shared_credentials_file = "${pathexpand("~/.aws/credentials")}"
}
resource "aws_vpc" "terraform-vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  enable_classiclink = "false"
  tags {
    Name = "Control VPC"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1b"
  tags {
    Name = "public"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags {
    Name = "Default"
  }
}

resource "aws_route_table_association" "association-subnet" {
  subnet_id = "${aws_subnet.public-1.id}"
  route_table_id = "${aws_route_table.rt1.id}"
}

data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "kops-admin" {
  name = "kops-role-attachment"
  roles = ["${aws_iam_role.kops-admin.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role" "kops-admin" {
  name               = "kops-admin-role"
  path               = "/"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "aws_iam_instance_profile" "kops-admin-profile" {
  name = "kops-admin-profile"
  role = "${aws_iam_role.kops-admin.name}"
}

resource "aws_instance" "terraform_linux" {
  ami = "ami-07683a44e80cd32c5"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.sshsg.id}"]
  subnet_id = "${aws_subnet.public-1.id}"
  key_name = "${aws_key_pair.kube_control_key.key_name}"
  lifecycle {
    create_before_destroy = true
  }
  tags {
    Name = "kops control instance"
  }
  user_data = "${file("scripts/control_instance_user_data.sh")}"
  iam_instance_profile = "${aws_iam_instance_profile.kops-admin-profile.name}"
}

resource "aws_key_pair" "kube_control_key" {
  key_name = "KubeControlKey"
  public_key = "${file("~/.ssh/DiegoTest.pub")}"
}

resource "aws_security_group" "sshsg" {
  name = "security_group_for_kub_control_ssh"
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "b" {
  bucket = "clusters.db.transfinity.systems"
  acl = "private"

  tags = {
    Name = "KOPS Clusters"
    Environment = "Dev"
    Region = "eu-west-1"
  }
}

output "vpc-id" {
  value = "${aws_vpc.terraform-vpc.id}"
}

output "vpc-publicsubnet" {
  value = "${aws_subnet.public-1.cidr_block}"
}

output "vpc-publicsubnet-id" {
  value = "${aws_subnet.public-1.id}"
}

output "instance-id" {
  value = "${aws_instance.terraform_linux.id}"
}

output "instance-public-ip" {
  value = "${aws_instance.terraform_linux.public_ip}"
}

output "key-id" {
  value = "${aws_key_pair.kube_control_key.key_name}"
}

output "s3-bucket" {
  value = "${aws_s3_bucket.b.bucket}"
}