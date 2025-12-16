#!/bin/bash
# This script destroys the Terraform-managed infrastructure and saves the configurations on the network devices.
# set your S3 credentials and Terraform variables
# set S3 URL if using a custom endpoint/ S3 compatible storage, otherwise remove it.

export AWS_ACCESS_KEY_ID="S3_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="S3_SECRET_ACCESS"
export TF_VAR_username="admin"
export TF_VAR_password="cisco"
export AWS_ENDPOINT_URL_S3="S3_ENDPOINTURL"
export TF_VAR_netbox_url="netbox_url"
export TF_VAR_netbox_token="netbox_token"

# Workaround for https://github.com/CiscoDevNet/terraform-provider-iosxe/issues/219
# Interfaces remain up after destroy - manually shutdown before destroying
echo "Shutting down managed interfaces before destroy..."

# Shutdown WAN interfaces (GigabitEthernet1) on all routers, set IPs accordingly.
for host in 192.168.2.220 192.168.2.221 192.168.2.222 192.168.2.223; do
  echo "Shutting down interfaces on $host..."
  sshpass -p "cisco" ssh -o StrictHostKeyChecking=no admin@$host << 'EOF'
conf t
interface GigabitEthernet1
shutdown
exit
exit
EOF
done

echo "Interfaces shut down. Proceeding with Terraform destroy..."

terraform init
terraform destroy

# Save configs after destroy
echo "Saving configurations to startup-config..."
for host in 192.168.2.220 192.168.2.221 192.168.2.222 192.168.2.223; do
  echo "Saving config on $host..."
  sshpass -p "cisco" ssh -o StrictHostKeyChecking=no admin@$host "write mem"
done

echo "All configurations saved!"