## Prerequisites

- A running K8s cluster and each node have ceph-common installed 

## Rook Operations
TBU

## Manual Ceph Operation instead of using Rook CRD

1. Setup
    ```
    ./deploy/rook/setup.sh
    ```

2. Create Ceph pool and volume
    ```
    ceph osd pool create kubernetes 8 8
    ceph osd lspools
    rbd create pv-vol --size 1G -p kubernetes
    ```

3. Update Ceph admin secret in static-pv.yaml
    ```
    ceph auth get-key client.admin | base64
    ```

3. Apply static-pv.yaml
    ```
    kubectl apply -f static-pv.yaml
    ```

4. Check mounted volume
    ```
    kubectl exec -it ceph-test -n ceph-test sh
    echo hello > /var/lib/ceph/output
    ```

5. Destroy
    ```
    rbd remove pv-vol -p kubernetes
    ./deploy/rook/destroy.sh
    ```

## Misc

### Rook Ceph Tool Pod
```
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
```