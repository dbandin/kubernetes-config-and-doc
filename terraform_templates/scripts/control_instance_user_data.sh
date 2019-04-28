#!/bin/bash
## kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin
### kops
wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops
### helm
HELMTARBIN="helm-v2.13.1-linux-amd64.tar.gz"
wget https://storage.googleapis.com/kubernetes-helm/$HELMTARBIN
tar -xvzf $HELMTARBIN
mv linux-amd64/helm  /usr/local/bin/
rm -rf linux-amd64 $HELMTARBIN
### tiller
cat <<EOF > /home/ec2-user/tiller-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: tiller-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: tiller
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: ""
EOF
chown ec2-user /home/ec2-user/tiller-rbac.yaml
### kops metadata storage
echo "export KOPS_STATE_STORE=s3://clusters.db.transfinity.systems" >> /etc/profile
### ssh key for cluster
mkdir -p /home/ec2-user/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDHMTTDHCM4v3uJvJUQrOGjjzgdKKb51i0WBNIKyJ32xR74JCH1R9wl58p4aFat5M1OZFc8Ayz5NBhhWWdPYMhMRjrsrEzojrj+t9uDDc4ZD7OAYZSfOdzXmU/nc1Nib0lz8HrLwZ3OAJuxvBt0Oczmzm6gIRYV7vQFpNOjzoPS+vjpL5SHXsQXMkrJrKHugWeEPMCLcihC2CAOYiiL/40Vh76iperJacBzanWpYg/5OiSE2k4qIYNIvUTaL/3XrfnBCf62M38N+JYoDwLTxNfJsFwHuZQ7izE2lYQ8+qSip68Y/hS1pYPxbhgSwXj+4wANWhMfbUEFawShWg5ho+5QlNy0zS1uTR9sdFGPW9UM/4SxgWx7EB+7uDVMSalCPc+v2uWY6jlm0tjki0WMK0BrW66qnIiLxtnHxyGeI1jK5WPi7TJb5QkwHpYLrwP9SWH7AwAv0wCzSoMpWua7ZWU0UtikWYT4e6tiXj0wq4e28NQ9V245EV5dZESkjZ+Ag/AdxmscqaSqi/hj9nFl6x+tR3LZQVwY5r76zQTFGW68SxxYG+ZPw8UTz86SRA4cmjpSLCSWMy1lFa7MvqlH4eOhedAf5RFa0mHOPJIUNDwaXreF5Y5ful/wwP4+UUfPjYbuVp7AYcS2zx961YznfxVeYtFrrungDujR7BtL6er+2w== Kube control isntance and cluster" > /home/ec2-user/.ssh/id_rsa.pub
chmod 400 /home/ec2-user/.ssh/id_rsa.pub
chmod 700 /home/ec2-user/.ssh
chown -R ec2-user /home/ec2-user/.ssh