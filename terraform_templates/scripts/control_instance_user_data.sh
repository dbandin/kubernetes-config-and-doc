#!/bin/bash
curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin
wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops
echo "export KOPS_STATE_STORE=s3://clusters.db.transfinity.systems" >> /etc/profile
mkdir -p /home/ec2-user/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC34r1uLIu8IaY7UdqLKIfNgsIm6onXwUYs65L6lAPJOPNCLToDL0Ib1OhdTv+NspRUDXJiTi+2vCX+8fAZUG8Yme5yAjCHYw6E8blvP8S+2QaMTSYeEm6BMGfFreABzwPq9lkDG5STnvJxtaxz0jyfl5SfWb+TVLE8xOgjUFIUS/kFyjVxg0ixztu2oqXyeGDri+TPStOLm+5XevubAHFCb5zXsoEQxWwtnb59e5tVwh0GKihCiSk3ORveGaaEclo4hvGjM50X7Qe6N9pUooTFO9qEApMWAnnzzGQ8yitnSVEhgjncUcUoxyIThqAb3jhqeo/i1KjVu4PLWHtEub1D" > /home/ec2-user/.ssh/id_rsa.pub
chmod 400 /home/ec2-user/.ssh/id_rsa.pub
chmod 700 /home/ec2-user/.ssh