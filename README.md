# OCP on CNV Helm Chart
This Helm Chart provides an OpenShift on OpenShift Virtualization deployment, using [fakefish](https://github.com/openshift-metal3/fakefish) as a Redfish API frontend, to manage the lifecycle of virtual machines.

Included with this Helm chart are the following resources:

- Virtual Machines
- Fakefish Deployment
- Service Endpoints for Fakefish
- Routes for Fakefish (to be controlled via the same cluster, or other external clusters)

**WARNING:** **DO NOT USE THIS IN PRODUCTION!** <br>

**NOTICE:** ***If you ***do not know what you're doing***, **you can expose your Redfish APIs to the internet with no protection**! This is because, by default, this Chart leverages OpenShift routes to expose the Redfish endpoints as (OpenShift would normally provide). If your cluster is exposed to the internet directly, then you want to use the settings listed in the [Networking Considerations](./#networking-considerations) section of this README.md***

## Prerequisites

- OpenShift Virtualization (Installed)
- NetworkNodeConfigurationPolicy (Deployed)
- NetworkAttachmentDefinition (Deployed)
- StorageClass Provisioner (Installed and Operational)
- Helm 3.x installed

## Installation

To install this Helm chart, you need to first ensure you've met the prerequisites. Then you can install the chart with these following steps:

1. Clone this repository.

2. Install the chart with the following command (you can use `--debug`, if you wish):

   ```bash
   helm install <release-name> ocp-on-cnv
   ```

   _Replace `<release-name>` with the name of your Helm deployment, as normal._

## Configuration

You can customize the deployment by modifying the `values.yaml` file. The following parameters can be configured:

- **Cluster Information**
  - `cluster.name`: Name of the cluster where these resources are being deployed to
  - `cluster.domain`: Domain of the cluster where these resources are being deployed to

- **Common Metadata**
  - `common.metadata.labels`: These labels will be applied "as is" to all resources for the Helm release
  - `common.metadata.annotations`: Annotations will also be applied "as is" to all the resources for the Helm release

- **Fakefish Image**
  - `fakefish.image`: The image to use for the fakefish API service.

- **Virtual Machine Configuration**
  - `VirtualMachine.baseName`: Base name for the Virtual Machine
  - `VirtualMachine.count`: Number of Virtual Machines to create
  - `VirtualMachine.resources.cpuCount`: Number of CPUs for the Virtual Machine
  - `VirtualMachine.resources.memoryCount`: Amount of memory for the Virtual Machine
  - `VirtualMachine.resources.disks`: Disk configurations (this is provided as a list, and added to the VMs as such)
  - `VirtualMachine.resources.storageClass`: `StorageClass` that will be used for the disks
  - `VirtualMachine.resources.network.networkName`: This is the name of the NetworkAttachmentDefinition which will be used for the VM.
  - `VirtualMachine.resources.network.baseMAC`: This base MAC address will be used for all of the resources. Any additional resources 00-99 will be added to the base MAC address.

- **Service Configuration**
  - `service.metalLBEnabled`: conditional that turns on or off MetalLB `annotations` for the Service objects.
  - `service.IPAddressPool`: Name of the MetalLB IP Address Pool to use (configures `annotations.metallb.universe.tf/address-pool`).
  - `service.loadBalancerIPs`: List of IPs to use for the LoadBalancer service (configures `annotations.metallb.universe.tf/loadBalancerIPs`).

- **Route Configuration**
  - `route.enabled`: conditional that turns on or off the routes for the Redfish/Fakefish service.
  - `route.port.targetPort`: The target port for the route.
  - `route.tls.termination`: The TLS termination policy for the route.
  - `route.tls.insecureEdgeTerminationPolicy`: The insecure edge termination policy for the route.

   The route configuration section may be turned into a map at some point in the future, which is in-line with the way that labels and annotations are handled today (currently it's only using single values in the Charts `values.yaml` file).

## Networking Considerations

Normally, if your cluster is not exposed to the internet directly, it would be fine to use this chart "as-is" (leveraging the OpenShift routes). However, if your cluster is exposed to the internet directly, you may want to consider the following changes to your `values.yaml` file:

```yaml
service:
  metalLBEnabled: true
  IPAddressPool: ippool-sample-01
  loadBalancerIPs:
    helm-ztp-node-00: "10.50.0.50"
    helm-ztp-node-01: "10.50.0.51"
    helm-ztp-node-02: "10.50.0.52"

route:
  enabled: false
  port:
    targetPort: http
  tls:
    termination: edge
    insecureEdgeTerminationPolicy: Allow
```

*Notice that both `route.enabled=false` and `service.metalLBEnabled=true` changes have been made, when comparing with the default settings found in [`values.yaml`](./ocp-on-cnv/values.yaml)*

But to do the above, you need to have MetalLB installed and configured on your cluster. If you do not have MetalLB installed, you can follow the instructions on [Red Hat's MetalLB documetnation](https://docs.openshift.com/container-platform/4.17/networking/networking_operators/metallb-operator/metallb-operator-install.html) or [MetalLB's documentation](https://metallb.universe.tf/).

## Usage

After installation, you can check the status of your release with:

```bash
helm status <release-name>
```

To upgrade the release with new configurations, modify the `values.yaml` file and run:

```bash
helm upgrade <release-name> ./ocp-on-cnv
```

## Uninstallation

To uninstall the chart, use the following command:

```bash
helm uninstall <release-name>
```

## Special Considerations

### Multi-Cluster Deployments with ACM

If you're attempting to use this chart across multiple clusters, this project will work just fine. There is a consideration that you will need to take into account, andd this is why I suggest using this chart for _development purposes_ and not for production environments.

On the ACM-side, you may need to add the following line item to your `Provisioning` object:

```yaml
apiVersion: metal3.io/v1alpha1
kind: Provisioning
metadata:
  name: provisioning-configuration
spec:
  disableVirtualMediaTLS: true     # <---- THIS LINE HERE
```

This suggestion has been made previously when using ACM with Supermicro X11 servers (read the following link [HERE](https://docs.openshift.com/container-platform/4.16/edge_computing/ztp-deploying-far-edge-sites.html#ztp-troubleshooting-ztp-gitops-supermicro-tls_ztp-deploying-far-edge-sites) for more information).

**How to identify if you need this recommended fix:** <br>
You can identify if you need this fix by checking the logs for the fakefish deployment (pod). If you see the following error message:

```bash
Waiting for ISO to be imported [8/60]
++ oc -n acm-ocpv get pvc helm-ztp-node-00-bootiso -o 'jsonpath={.metadata.annotations.cdi\.kubevirt\.io/storage\.condition\.running\.message}'
+ STATUS='Unable to connect to http data source: HTTP request errored: Get "https://192.168.1.172:6183/redfish/boot-7847b914-f008-4969-9196-6d58ee165204.iso": tls: failed to verify certificate: x509: cannot validate certificate for 192.168.1.172 because it doesn'\''t contain any IP SANs'
+ '[' 0 -ne 0 ']'
+ [[ Unable to connect to http data source: HTTP request errored: Get "https://192.168.1.172:6183/redfish/boot-7847b914-f008-4969-9196-6d58ee165204.iso": tls: failed to verify certificate: x509: cannot validate certificate for 192.168.1.172 because it doesn't contain any IP SANs != \I\m\p\o\r\t\ \C\o\m\p\l\e\t\e ]]
+ WAIT=10
+ sleep 2
+ '[' 10 -ge 60 ']'
```

If you see the error above, then you will need to add the `disableVirtualMediaTLS: true` line item to your `Provisioning` object. In the error message above, `192.168.1.172` is the remote ACM server.

If you already have ACM deployed, you can `patch` the current in-place `Provisioning` object with the following command:

```bash
oc patch provisioning provisioning-configuration --type merge -p '{"spec":{"disableVirtualMediaTLS": true}}'
```

Follow this up with a `rollout` command for the `metal3-state` deployment:

```bash
oc rollout restart $(oc get deployments -n openshift-machine-api -l baremetal.openshift.io/cluster-baremetal-operator=metal3-state -o name --no-headers=true) -n openshift-machine-api
```
