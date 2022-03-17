# Vault

![Vault](https://img.shields.io/badge/-vault-000000?style=for-the-badge&logo=Vault&logoColor=white)

Deploying Vault on K8s via Kustomize and using Raft Integrated Storage as Backend

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Vault](#vault)
    - [vault.hcl configMap](#vaulthcl-configmap)
    - [vault-role](#vault-role)
    - [vault-service-active](#vault-service-active)
    - [Initializing Vault](#initializing-vault)
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

### vault-service-active 
- Kubernetes service that uses the dynamic labels of Vault to route traffic only to the active vault leader via the selector `vault-active: "true"`
- Initially when vault pod is up and running this service will not map to it since it's not yet initialized (There's no EndPoint), in order for the service to route to the pod, vault should be initialized

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

### Useful Resources 
1. [Vault on Kubernetes Deployment Guide](https://learn.hashicorp.com/tutorials/vault/kubernetes-raft-deployment-guide?in=vault/kubernetes)
2. [Integrated Storage (Raft) Backend](https://www.vaultproject.io/docs/configuration/storage/raft)
3. [Kubernetes Service Registration](https://www.vaultproject.io/docs/configuration/service-registration/kubernetes)
4. [5 best practices to get to production readiness with Hashicorp Vault in Kubernetes](https://expel.com/blog/production-readiness-hashicorp-vault-kubernetes/)