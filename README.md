# Vault

![Vault](https://img.shields.io/badge/-vault-000000?style=for-the-badge&logo=Vault&logoColor=white)

Deploying Vault on K8s via Kustomize and using Raft Integrated Storage as Backend

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [vault.hcl configMap](#vaulthcl-configmap)
- [vault-role](#vault-role)
- [Services](#services)
  - [vault-service-active](#vault-service-active)
  - [vault-service-headless](#vault-service-headless)
- [vault-cronjob-daily-snapshot](#vault-cronjob-daily-snapshot)
- [Initializing Vault](#initializing-vault)
- [High Availability with Integrated Storage](#high-availability-with-integrated-storage)
- [Backup and Restore Scenario](#backup-and-restore-scenario)
- [Useful Resources](#useful-resources)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

### vault.hcl configMap
- `conf/vault.hcl` is used as the configuration file for vault, it contains the necessary stanzas to define storage backend in use ([Integrated storage](https://www.vaultproject.io/docs/configuration/storage/raft) in this case)
- The **[kubernetes service registeration](https://www.vaultproject.io/docs/configuration/service-registration/kubernetes)** section allows tagging vault pods, this is useful for identifying the state of each pod in the cluster and based on it the service `vault-service-active` was created in order to map only to the active leader

---

### vault-role
- Required with permissions to at least `get`, `update` and `patch` pods in order for kubernetes service registeration to function
- Results in having the following [label definitions](https://www.vaultproject.io/docs/configuration/service-registration/kubernetes#label-definitions)
  1. vault-active
  2. vault-initialized
  3. vault-perf-standby
  4. vault-sealed
  5. vault-version

---
### Services
#### vault-service-active 
- Kubernetes service that uses the dynamic labels of Vault to route traffic only to the active vault leader via the selector `vault-active: "true"`
- Initially when vault pod is up and running this service will not map to it since it's not yet initialized (There's no EndPoint), in order for the service to route to the pod, vault should be initialized

---

#### vault-service-headless
- A service is becomes headless by specifying `clusterIP: None`
- It's the service referenced by the StatefulSet `serviceName` key 
- headless service returns list of IPs for the associated pods
- A StatefulSet needs a headlessService for Pods discovery and to maintain the Pods sticky network identity

---

### vault-cronjob-daily-snapshot
- CronJob that will run daily at 11 AM to take a snapshot and upload it to Minio
- It's based on the image generated via the [Dockerfile](https://github.com/theJaxon/Vault/blob/main/Dockerfile) in the root of this repository, the image uses [minideb](https://github.com/bitnami/minideb) as a base then adds vault + mc CLIs
- Rest of the needed configurations are handled as environment variables

---

### Initializing Vault 
```bash
kubectl exec -it vault-0 -n vault /bin/sh

# Generates the 5 unseal keys used to consturct the master key 
# Generates vault root token 
vault operator init

# Unseals vault resulting in the pod having vault-active: true label
vault operator unseal <3 keys>
```

---

### High Availability with Integrated Storage 
- Setting StatefulSet replicas to `3` then applying the kubernetes resources will result in initially `vault-0` pod being scheduled, it needs to be intialized and vault needs to be unsealed 
- After unsealing the pod `vault-1` will also be scheduled but the readiness probe will fail as it needs to be initialized (We'll make it join `vault-0`) as follows 
```bash
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-headless:8200
kubectl exec -ti vault-1 -- vault operator unseal <3-keys>

Key       Value
---       -----
Joined    true

```
- Same procedure will be done to `vault-2` and we can list all the available nodes with the command 
```bash 
kubectl exec -ti vault-0 
export VAULT_TOKEN=<token>
vault operator raft list-peers

Node                                    Address                        State       Voter
----                                    -------                        -----       -----
8bc7e17f-2640-bd3b-76d2-f8440f22c10a    vault-0.vault-headless:8201    leader      true
b2507758-85d4-c4f5-bf19-575eb900bf8f    vault-1.vault-headless:8201    follower    true
b1a97d24-ad93-1fb4-4429-e4fbae3f8eef    vault-2.vault-headless:8201    follower    true
```

---

### Backup and Restore Scenario 
- Backups will be stored in MinIO as follows 
```bash
# Take snapshot with current date as the name
vault operator raft snapshot save `date +"%d-%m-%Y"`.snap

# Upload to minio hosted instance
mc cp `date +"%d-%m-%Y"`.snap minio/vault
```

- Assume that the situation is that the main vault instance was running without a PVC and now data is lost but fortunately we took the snapshot 
- Start by initializing the vault instance once again 
```bash
vault operator init
vault operator unseal <3-keys>
export VAULT_TOKEN=<token>

# Download snapshot from minio
mc cp minio/vault/21-03-2022.snap 21-03-2022.snap

# Restore 
vault operator raft snapshot restore -force 21-03-2022.snap

```
- Now unseal once again but this time using the old key shares and old token

---

### Useful Resources 
1. [Vault on Kubernetes Deployment Guide](https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes)
2. [Integrated Storage (Raft) Backend](https://www.vaultproject.io/docs/configuration/storage/raft)
3. [Kubernetes Service Registration](https://www.vaultproject.io/docs/configuration/service-registration/kubernetes)
4. [5 best practices to get to production readiness with Hashicorp Vault in Kubernetes](https://expel.com/blog/production-readiness-hashicorp-vault-kubernetes/)