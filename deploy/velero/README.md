## Summary
Don't use **kind** to try _volume snapshot backup_ because kind supports hostPath storage class by default not including dynamic volume provision and node container does not have mount.nfs installed.

Also, Velero does not support **hostPath** as the volume backup location. Instead for testing purpose, you can **minikube** which also include mount.nfs client.

## Prerequisites
- A running K8s cluster and each node have mount.nfs supported.
