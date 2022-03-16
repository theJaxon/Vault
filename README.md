# Vault

![Vault](https://img.shields.io/badge/-vault-000000?style=for-the-badge&logo=Vault&logoColor=white)

Deploying Vault on K8s via Kustomize and using Raft Integrated Storage as Backend

### vault.hcl configMap
- `conf/vault.hcl` is used as the configuration file for vault, it contains the necessary stanzas to define storage backend in use ([Integrated storage](https://www.vaultproject.io/docs/configuration/storage/raft) in this case)
- The **[kubernetes service registeration](https://www.vaultproject.io/docs/configuration/service-registration/kubernetes)** section allows tagging vault pods, this is useful for identifying the state of each pod in the cluster and based on it the service `vault-service-active` was created in order to map only to the active leader

### vault-service-active 
- Kubernetes service that uses the dynamic labels of Vault to route traffic only to the active vault leader via the selector `vault-active: "true"`
- Initially when vault pod is up and running this service will not map to it since it's not yet initialized, in order for the service to route to the pod the following should be done 
```bash
kubectl exec -it vault-0 

# Generates the 5 unseal keys used to consturct the master key 
# Generates vault root token 
vault operator init

# Unseals vault resulting in the pod having vault-active: true label
vault operator unseal <3 keys>
```