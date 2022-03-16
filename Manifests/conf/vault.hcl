# https://www.vaultproject.io/docs/configuration#disable_mlock
disable_mlock = true
ui            = true

# Storage Backend Configuration - Raft (Integrated Storage)
storage "raft" {
  retry_join {
    leader_api_addr = "http://vault-active.vault:8200"
  }
}

listener "tcp" {
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable     = 1
}

service_registration "kubernetes" {}