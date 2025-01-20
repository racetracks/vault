# Create vm

OS: RHEL 9

specs: 
2vcpu
4gb memory
55gb os disk

create DNS record

# username configuration
set default username as admin
store password in password vault 

/!\ do not align with current rhel build process, ensure root account is not allowed for remote login /!\

# configure OS basine security

# upload cis workbench 
upload cis workbench bundle from https://workbench.cisecurity.org/files/5522

# extract and install cis benchmark

    tar -xvf CIS_Red_Hat_Enterprise_Linux_9_Benchmark_v2.0.0_Build_Kit_v1.tar.gz
    bash red_hat_enterprise_linux_9_benchmark_v2.0.0.sh  -s -p "Level 1 - Server"
    bash red_hat_enterprise_linux_9_benchmark_v2.0.0.sh  -s -p "Level 2 - Server"


# note that this enables selinux and sets to targeted policy.
# if mls is required, be aware of the need to label processes that are suitable to run in user mode.


# set password expiry for admin account
    ## CIS benchmarks set the flag for accounts to force admin password expiry.  this locks us out as soon as we reboot
    sudo chage -M -1 admin


#this sets the account "admin" to have password never expires, this is required to prevent lockout as the device will always be offline, for minimum 1 year at a time in order to regenerate the crl (and renew issuing ca certs)









# Install core prerequisites



    yum update
    yum install open-vm-tools -y
    yum install yum-utils -y

# install hashicorp yum repo

    yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo


    yum install -y curl wget unzip jq net-tools policycoreutils-python-utils


# install vault and consul

    sudo yum -y install consul vault




# create consul user

    sudo useradd --system --home /etc/consul.d --shell /bin/false consul

    sudo mkdir -p /etc/consul.d /var/lib/consul

    sudo chown -R consul:consul /etc/consul.d /var/lib/consul

    sudo chmod -R 750 /etc/consul.d /var/lib/consul

    sudo chage -M -1 consul


# create vault user

    sudo useradd --system --home /etc/vault.d --shell /bin/false vault

    sudo mkdir -p /etc/vault.d /var/lib/vault

    sudo chown -R vault:vault /etc/vault.d /var/lib/vault

    sudo chmod -R 750 /etc/vault.d /var/lib/vault

    sudo chage -M -1 vault



# create service definitions
    touch /etc/systemd/system/consul.service
    touch /etc/systemd/system/vault.service

    # copy contents of consul.service and vault.service from this repo 
    # not the IP address that must change to match the servers ip address








# Create certificate for vault and consul

    openssl req -newkey rsa:4096 -x509 -sha256 -days 18250 -nodes \
    -out /home/admin/vault-consul-cert.pem \
    -keyout /home/admin/vault-consul-key.pem \
    -subj "/CN=lab-ssrca.spicysamosa.com" \
    -addext "subjectAltName=DNS:lab-ssrca.spicysamosa.com,IP:10.4.61.200,DNS:localhost,IP:127.0.0.1,DNS:server.dcl.consul"



# copy the certificate to vault and consul

    cp vault-consul-key.pem /etc/vault.d/vault-consul-key.pem
    cp vault-consul-cert.pem /etc/vault.d/vault-consul-cert.pem


    cp vault-consul-key.pem /etc/consul.d/vault-consul-key.pem
    cp vault-consul-cert.pem /etc/consul.d/vault-consul-cert.pem


# set certificate permissions

    sudo chown vault:vault /etc/vault.d/vault-consul-*.pem
    sudo chmod 600 /etc/vault.d/vault-consul-*.pem
    sudo chown consul:consul /etc/consul.d/vault-consul-*.pem
    sudo chmod 600 /etc/consul.d/vault-consul-*.pem


# create consul config file


    mv /etc/consul.d/consul.hcl /etc/consul.d/consul.hcl.original
    touch /etc/consul.d/consul.hcl

    # copy configuration from this repo to the file created above



# Enumerate consul as service and start

    sudo systemctl daemon-reload 
    sudo systemctl enable consul
    sudo systemctl start consul


# create firewall rule to allow consul traffic

    sudo firewall-cmd --add-port=8500-8501/tcp --permanent
    sudo firewall-cmd --reload





# Create vault configuration file
 


    mv /etc/vault.d/vault.hcl /etc/vault.d/vault.hcl.original
    touch /etc/vault.d/vault.hcl
    # copy /etc/vault.d/vault.hcl from vault configurations in this repo
    # modify the contents of the file to match the IP address of the server

# create firewall rule to allow vault traffic

    sudo firewall-cmd --add-port=8200-8201/tcp --permanent
    sudo firewall-cmd --reload



# start vault service
    
    sudo systemctl daemon-reload
    sudo systemctl enable vault
    sudo systemctl start vault



# initialize vault
 



    vault operator init > /etc/vault.d/init-keys.txt
    vault operator unseal <UNSEAL_KEY>

    export VAULT_ADDR=https://<PRIVATE_IP>:8200
    export VAULT_SKIP_VERIFY=true
    vault login <ROOT_TOKEN>


    vault secrets enable pki
    vault secrets tune -max-lease-ttl=87600h pki

