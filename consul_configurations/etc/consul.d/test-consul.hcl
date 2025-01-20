# Consul server configuration for Vault storage backend
server = true
node_name = "consul-server-1"
datacenter = "dc1"
data_dir = "/opt/consul/data"
bind_addr = "127.0.0.1"  # Local interface only for a single-node setup
advertise_addr = "127.0.0.1"  # Advertise this address for communication

# Enable HTTPS for communication
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true

# Define TLS certificates
ca_file = "/etc/consul.d/ca.pem"         # CA certificate
cert_file = "/etc/consul.d/consul-cert.pem"  # Consul server certificate
key_file = "/etc/consul.d/consul-key.pem"   # Consul server private key

# Client/Agent binding for internal connections
client_addr = "127.0.0.1"  # Restrict Consul to local client connections

# Enable ACLs if you are going to use them
acl = true
acl_default_policy = "allow"
acl_down_policy = "extend-cache"

# Start a single node
bootstrap_expect = 1

# Set the communication port
ports = {
  http = 8500    # HTTP port for the Consul UI and HTTP API
  https = 8501   # Secure HTTP port
  serf = 8301    # Internal node-to-node communication
  server = 8300  # Server communication (TLS enabled)
  rpc = 8400     # RPC for internal communication
}

# Enable Consul UI (optional for local usage)
ui = true

# Enable automatic management of Raft logs (important for single-node mode)
log_level = "INFO"
log_file = "/opt/consul/consul.log"
