# https://www.vaultproject.io/docs/configuration#disable_mlock
disable_mlock = true
ui            = true

# Storage Backend Configuration - Raft (Integrated Storage)
storage "raft" {}

listener "tcp" {
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable     = 1
}

service_registration "kubernetes" {}