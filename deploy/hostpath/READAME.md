The default host path provisioner (kubernetes.io/host-path) does not support dynamic persistent volume provision. 

For testing dynamic provision easier w/o extra resource and setup especially use Kind as K8s development environment, by using `rimusz/hostpath-provisioner` it is able to achieve dynamic volume provision.
