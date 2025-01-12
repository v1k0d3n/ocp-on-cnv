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

2. Make sure that the `kubeconfig` for the cluster you want to install this chart to is exported, and in order to dynamically pass the `kubeconfig` to the chart as a base64 encoded string, you need run these commands (example shown below):

   ```bash
   export KUBECONFIG="/Users/v1k0d3n/.kube/kubeconfig"
   export KUBECONFIG_CONTENT=$(cat "$KUBECONFIG" | base64 | tr -d '\n')
   ```

3. Install the chart with the following command (you can use `--debug`, if you wish):

   ```bash
   helm install <release-name> ocp-on-cnv --set secret.kubeconfigContent="$KUBECONFIG_CONTENT"
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

- **Virtual Machine Configuration**
  - `VirtualMachine.baseName`: Base name for the Virtual Machine
  - `VirtualMachine.count`: Number of Virtual Machines to create
  - `VirtualMachine.resources.cpuCount`: Number of CPUs for the Virtual Machine
  - `VirtualMachine.resources.memoryCount`: Amount of memory for the Virtual Machine
  - `VirtualMachine.resources.disks`: Disk configurations (this is provided as a list, and added to the VMs as such)
  - `VirtualMachine.resources.storageClass`: `StorageClass` that will be used for the disks
  - `VirtualMachine.resources.network.networkName`: This is the name of the NetworkAttachmentDefinition which will be used for the VM.
  - `VirtualMachine.resources.network.baseMAC`: This base MAC address will be used for all of the resources. Any additional resources 00-99 will be added to the base MAC address.

- **Secrets Configuration**
  - `secret.kubeconfigContent`: This will normally be left blank and provided at runtime with the install example (above), however if you're feeling spicy you can place your Base64 encoded kubeconfig output here instead.

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
