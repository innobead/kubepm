# k8s-utils

This is a project about setting up K8s development, runtime and solution environment.

## Prerequisites

Right now, this repo only supports openSUSE LEAP and Tumbleweed.

## Install tools
```
➜  k8s-utils git:(master) ✗ ./bin/install-dev.sh      
Configurable Variables:
 KU_FORCE_INSTALL=false
 KU_INSTALL_BIN=/usr/local/bin
 KU_INSTALL_DIR=/usr/local/lib
 KU_SKIP_SETUP=false
 KU_TMP_DIR=/tmp
 KU_USER=davidko
 KU_ZYPPER_INSTALL_OPTS='-y -l'

Command Usage:
  ./bin/install-dev.sh [ sdkman | bazel | snap | gofish | go | gradle | python | ruby | rust | protobuf | jwt | all ]

➜  k8s-utils git:(master) ✗ ./bin/install-k8s-tools.sh          
Configurable Variables:
 KU_FORCE_INSTALL=false
 KU_INSTALL_BIN=/usr/local/bin
 KU_INSTALL_DIR=/usr/local/lib
 KU_SKIP_SETUP=false
 KU_TMP_DIR=/tmp
 KU_USER=davidko
 KU_ZYPPER_INSTALL_OPTS='-y -l'

Command Usage:
  ./bin/install-k8s-tools.sh [ kind | minikube | helm | kubectl | velero | footloose | krew | skaffold | kubebuilder | controllertools | kustomize | all ]

➜  k8s-utils git:(master) ✗ ./bin/install-runtime.sh  
Configurable Variables:
 KU_FORCE_INSTALL=false
 KU_INSTALL_BIN=/usr/local/bin
 KU_INSTALL_DIR=/usr/local/lib
 KU_SKIP_SETUP=false
 KU_TMP_DIR=/tmp
 KU_USER=davidko
 KU_ZYPPER_INSTALL_OPTS='-y -l'

Command Usage:
  ./bin/install-runtime.sh [ docker | libvirt | virtualbox | vagrant | all ]

➜  k8s-utils git:(master) ✗ ./bin/install-tools.sh           
Configurable Variables:
 KU_FORCE_INSTALL=false
 KU_INSTALL_BIN=/usr/local/bin
 KU_INSTALL_DIR=/usr/local/lib
 KU_SKIP_SETUP=false
 KU_TMP_DIR=/tmp
 KU_USER=davidko
 KU_ZYPPER_INSTALL_OPTS='-y -l'

Command Usage:
  ./bin/install-tools.sh [ terraform | oci_tools | salt | cert_tools | ldap_tools | cloud_tools | all ]

```

## Deploy applications/services
```
➜  k8s-utils git:(master) ✗ ./deploy/kind/install.sh 
➜  k8s-utils git:(master) ✗ ./deploy/kind/uninstall.sh 
```