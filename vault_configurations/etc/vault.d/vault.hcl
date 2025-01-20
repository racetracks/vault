storage "consul" {
        address = "127.0.0.1:8500"
        path = "vault/"
        scheme = "https"
        tls_ca_file = "/etc/vault.d/vault-consul-cert.pem"
        tls_cert_file = "/etc/vault.d/vault-consul-cert.pem"
        tls_key_file = "/etc/vault.d/vault-consul-key.pem"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 0
  tls_cert_file = "/etc/vault.d/vault-consul-cert.pem"
  tls_key_file = "/etc/vault.d/vault-consul-key.pem"
}

api_addr = "https://10.4.61.200:8200"
cluster_addr = "https://10.4.61.200:8201"
ui = true