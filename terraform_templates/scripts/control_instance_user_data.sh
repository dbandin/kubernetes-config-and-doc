  #!/bin/bash
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
  chmod +x kubectl
  mv kubectl /usr/local/bin
  wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
  chmod +x kops-linux-amd64
  mv kops-linux-amd64 /usr/local/bin/kops
