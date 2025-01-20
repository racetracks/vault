# Guide: Creating a 100-Year Root Certificate and a 50-Year Certificate for Vault and Consul with Mutual TLS

This guide explains how to create a 100-year self-signed root certificate and a subordinate certificate valid for 50 years. Both Vault and Consul will use the subordinate certificate for mutual TLS (mTLS) communication. It also includes instructions for configuring Consul to use the certificate.

## Step 1: Create a Root Certificate Authority (CA)
The root CA is used to sign the subordinate server certificate.

```bash
# Generate a private key for the root CA
openssl genrsa -out ca-key.pem 4096

# Create a self-signed root CA certificate valid for 100 years (36,500 days)
openssl req -x509 -new -nodes -key ca-key.pem -sha256 -days 36500 -out ca.pem -subj "/CN=Consul-Vault-Root-CA"
```

- `ca-key.pem`: Private key for the root CA (keep secure).
- `ca.pem`: Public certificate for the root CA (shared with all nodes).

---

## Step 2: Generate the Subordinate Certificate and Key for Vault and Consul
Both Vault and Consul will use the subordinate certificate.

### 2.1: Generate a Private Key
```bash
openssl genrsa -out vault-consul-key.pem 2048
```

### 2.2: Create a Certificate Signing Request (CSR)
```bash
openssl req -new -key vault-consul-key.pem -out vault-consul.csr -subj "/CN=*.example.com"
```

- Replace `*.example.com` with your organization’s domain or the appropriate wildcard/domain name.

### 2.3: Create a SAN Configuration File
The Subject Alternative Name (SAN) configuration ensures compatibility with all the required domains and IPs.

Create a file named `san.cnf`:
```plaintext
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = consul
DNS.2 = vault
DNS.3 = localhost
IP.1 = 127.0.0.1
IP.2 = <your-server-ip>
```

- Replace `<your-server-ip>` with the actual IP address of your server.
- Add additional `DNS` or `IP` entries as needed.

### 2.4: Sign the Subordinate Certificate with the Root CA
```bash
openssl x509 -req -in vault-consul.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial     -out vault-consul.pem -days 18250 -sha256 -extfile san.cnf -extensions v3_req
```

- `vault-consul.pem`: The signed subordinate certificate.
- `ca.srl`: Serial number file for the root CA.

---

## Step 3: Verify the Certificate
Ensure the subordinate certificate is valid and properly signed by the root CA.

```bash
openssl verify -CAfile ca.pem vault-consul.pem
```

---

## Step 4: Configure Consul to Use the Certificate
Update the Consul configuration to enable mTLS and use the subordinate certificate.

### 4.1: Example Consul Configuration (`consul.hcl`)
```hcl
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true

tls {
    ca_file   = "/path/to/ca.pem"
    cert_file = "/path/to/vault-consul.pem"
    key_file  = "/path/to/vault-consul-key.pem"
}
```

- Replace `/path/to/` with the actual file paths to your certificates and keys.

### 4.2: Reload Consul
Restart Consul to apply the configuration changes:

```bash
systemctl restart consul
```

---

## Step 5: Configure Vault to Use the Certificate
Update the Vault configuration to use the subordinate certificate for mTLS.

### 5.1: Example Vault Configuration (`vault.hcl`)
```hcl
listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_cert_file = "/path/to/vault-consul.pem"
    tls_key_file  = "/path/to/vault-consul-key.pem"
}

api_addr = "https://<vault-server-ip>:8200"
cluster_addr = "https://<vault-server-ip>:8201"
```

- Replace `<vault-server-ip>` with the actual IP address of the Vault server.
- Ensure the certificate and key paths match the files you created.

### 5.2: Reload Vault
Restart Vault to apply the configuration changes:

```bash
systemctl restart vault
```

---

## Summary of Generated Files
1. `ca.pem`: Root CA certificate (shared with all nodes).
2. `ca-key.pem`: Private key for the root CA (keep secure).
3. `vault-consul.pem`: Subordinate certificate for Vault and Consul.
4. `vault-consul-key.pem`: Private key for Vault and Consul.
5. `san.cnf`: SAN configuration file (used for signing).

---

## Security Recommendations
- **Secure Private Keys**: Keep `ca-key.pem` and `vault-consul-key.pem` in a secure location.
- **Restrict Access**: Use appropriate file permissions to restrict access to the certificate and key files.
- **Network Security**: Place Consul and Vault behind a firewall or within a private network.

With this configuration, Consul and Vault will communicate securely using mTLS, with the subordinate certificate valid for 50 years and the root CA valid for 100 years.
