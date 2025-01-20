verify_incoming = false
verify_outgoing = false
verify_server_hostname = false

ca_file = "/etc/consul.d/vault-consul-cert.pem"
cert_file = "/etc/consul.d/vault-consul-cert.pem"
key_file = "/etc/consul.d/vault-consul-key.pem"

auto_encrypt {
  allow_tls = true
}
ui_config {
        enabled = true
}
ports {
        https = 8500
        http = -1
}



