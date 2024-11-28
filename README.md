FILA3 Voting App Terraform Project
===================================

# Table of Content

  * [Objectives](#objectives)
  * [Part 1 - Local Docker deployment](#part-1---local-docker-deployment)
  * [Part 2 - GCP GKE Deployment](#part-2---gcp-gke-deployment)
  * [Part 2.2 optional - Offloaded Redis DB](#part-2.2-optional---offloaded-redis-db)
  * [Debugging tips](#debugging-tips)
  * [Destroy everything](#destroy-everything)

## Objectives

The objective is to use Terraform to deploy the voting app.

The tutorial on Terraform did not give you _all_ elements for this project: it was on purpose.
The point is for you to learn how to seek information in providers and other documentations.
But most elements in the tutorials can be directly applied.

Different levels are possible, the more advancement you make the better.
Part 1 and Part 2 are considered two different deployment infrastructure, they must be in different directories.
*Part 2.2 and "Improvements" are optional*

We expect a URL to a git repository with your code and a thorough README with at least

* How to use the repo (where to apply terraform, in which order, scripts to execute if any, where to put our GCP credentials, etc.)
* The architecture design:
  * mechanism used for reusing small pieces of the infrastructure (either `modules` or `terraform_remote_state` or a combination of both)
  * mechanism used for setting values of input `variable`s (location and name of the `.tfvars` files, which environment variables to set, etc.)
* Explanations on your choices.


## Part 1 - Local Docker deployment

![voting-app-docker](figures/login-nuage-voting.drawio.svg)

In this first part, you must write Terraform code that builds and deploys the voting services with the Docker provider.
The app will thus be deployed locally inside containers on your machine.

Use the given `docker-compose.yml` as a reference configuration.

**TIP**: Recall that a Docker Compose "service" creates a DNS record accessible by other containers.
Terraform does not do that, so you will need to add the relevant `host` configurations.

*Improvement*: Make so that `apply` rebuilds an image if the files in the voting service directory have changed.


## Part 2.1 - GCP GKE Deployment

![voting-app-k8s](figures/login-nuage-voting-k8s.drawio.svg)

In this second part, you must write code that deploys the voting services onto a Kubernetes cluster provisioned with Terraform on GKE.
Google and Kubernetes providers will be thus be used.

Unlike the tutorials and for simplicity, use a `data` source to read the GCP predefined `default` network and use it for configuring the cluster network.

The YAML manifest files are given in `k8s-manifests/`. Use at least one `count` or `for_each`.

**TIP**: You can use the `kubernetes_manifest` resource and give it a YAML manifest directly.

*Improvements*:

  * Make it work without modifying the given YAML manifest (except the `image` repo of deployment containers).
  * Make so that `apply` rebuilds and repush an image if the code of the voting service have changed.
  * Reuse the `docker_image`s from Part 1.


## Part 2.2 optional - Offloaded Redis DB

In this last part, you must deploy with Terraform the `Redis` database inside a VM on GCP rather than on the cluster.
To install Redis upon startup of the VM, use the given `install-redis.sh.tftpl` template script in the `metadata_startup_script` attribute.

This database must be reachable to the other components of the application located on the GKE cluster.

**TIP**: You will need a `google_compute_firewall` resource to allow port `6379` on `source_ranges` `0.0.0.0/0`.
Don't forget to link the firewall rule to the VM through a shared *tag*.

Services *vote* and *worker* need to be aware of the Redis host IP and password.

*Improvements*:

  * Refine the firewall rule so that only machines from the cluster can reach the VM.
  * Put the cluster on a dedicated network and the redis VM on another network.


## Debugging tips

* Ping from inside a Deployment's pod:
  * Launch bash on a pod, e.g.: `kubectl exec deployments/vote-deplt -it -- bash` then
  * Install the `ping` command: `apt update; apt install iputils-ping`
  * Check connectivity: `ping redis -p 6379`

* Pod for debugging networking: https://hub.docker.com/r/rtsp/net-tools
  * Start the pod: `kubectl run net-debug --image rtsp/net-tools`, then
  * Launch an interactive bash session: `kubectl exec net-debug -it -- bash` or
  * Launch a single command, e.g.: `kubectl exec net-debug -- nslookup redis`

* Pod for debugging Redis:
  * Start the pod: `kubectl run redis-debug --image redis:alpine`
  * Check the connection: `kubectl exec redis-debug -it -- redis-cli -h redis -pass '{yourpassword}'`

* Start a SSH connection on the GCP VM:
  * `gcloud compute ssh {VM_NAME}`


## Destroy everything

Do not forgot to destroy all resources, especially the K8S cluster.
```
$ terraform destroy
```

Remember to set `deletion_protection = true` in the `google_container_cluster` resource. Edit the `terraform.tfstate` file in your editor or run the following
```
    sed -e '/deletion_protection/s/true/false/' -i terraform.tfstate
```

