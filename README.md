# Network CI/CD with Terraform and Drone

Automate Cisco network device configuration using Terraform, the IOSXE provider, and Drone CI/CD pipelines. This project demonstrates infrastructure-as-code principles applied to network automation.

## Overview

- **Infrastructure as Code** for Cisco IOSXE devices using Terraform
- **CI/CD automation** with Drone pipelines
- **Remote state management** with MinIO (S3-compatible, BYOS3 if you like)
- **Modular configuration** for scalability
- **NETCONF-based** device management

## Architecture

```
GitHub → Drone Pipeline → MinIO (State)
              ↓
        NETCONF/YANG
              ↓
    Cisco Network Devices
  (P-01, P-02, DR-01, DR-02)
```

**Key Design Patterns:**
- Single `iosxe` provider manages all devices via NETCONF
- Device inventory in `devices.tf` drives all module configurations
- Interface data in `interfaces.tf` (local values, not resources)
- Modules use `for_each` with device names as keys
- Explicit config saving via `iosxe_save_config` resource

## Prerequisites

- Cisco IOS-XE devices with NETCONF enabled
- Drone CI/CD server (optional, for automated deployments)
- MinIO server for Terraform state storage (S3-compatible)
- Terraform >= 1.0
- SSH access to devices (for `destroy.sh` script)

### Enable NETCONF on Devices

```cisco
conf t
netconf-yang
netconf-yang cisco-odm polling-enable
```

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/your-org/Network-CICD.git
cd Network-CICD
```

Edit [`devices.tf`](devices.tf ) with your device inventory:

```hcl
locals {
  routers = {
    "P-01" = {
      host = "192.168.2.220"
      role = "primary"
    }
    # Add more devices...
  }
}
```

### 2. Set Up Drone Secrets

```bash
drone secret add --repository your-org/Network-CICD --name tf_username --data "admin"
drone secret add --repository your-org/Network-CICD --name tf_password --data "cisco"
drone secret add --repository your-org/Network-CICD --name MINIO_ACCESS_KEY --data "your-key"
drone secret add --repository your-org/Network-CICD --name MINIO_SECRET_KEY --data "your-secret"
drone secret add --repository your-org/Network-CICD --name MINIO_ENDPOINT --data "http://minio:9000"
```

### 3. Deploy

**Via Drone:**
```bash
drone build create your-org/Network-CICD --event push
```

**Locally:**
```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_ENDPOINT_URL_S3="http://minio-host:9000"
export TF_VAR_username="admin"
export TF_VAR_password="cisco"

terraform init
terraform plan
terraform apply
```

## Project Structure

```
Network-CICD/
├── main.tf                    # Provider & module configuration
├── backend.tf                 # Remote state (MinIO S3)
├── devices.tf                 # Device inventory (routers, switches)
├── interfaces.tf              # Interface data definitions
├── variables.tf               # Input variables (credentials)
├── .drone.yml                 # CI/CD pipeline (4 stages)
├── destroy.sh                 # Safe cleanup with interface shutdown
└── modules/
    ├── snmp/                  # SNMP configuration
    ├── banner/                # Login banner configuration
    └── interfaces_core_wan/   # WAN interface management
```

## Available Modules

### SNMP
Configures SNMP contact, chassis ID, and other SNMP server settings on routers.

### Banner
Applies login warning banners to all router devices.

### WAN Interfaces
Configures WAN uplink interfaces (GigabitEthernet) with IP addressing, MTU, and bandwidth settings. Interface data is defined in `interfaces.tf` as local values.

## Destroying Configuration

```bash
chmod +x destroy.sh
./destroy.sh
```

**Important**: Always use `destroy.sh` instead of `terraform destroy` directly. The script:
1. Shuts down managed interfaces via SSH (workaround for [provider bug #219](https://github.com/CiscoDevNet/terraform-provider-iosxe/issues/219) where interfaces remain up after destroy)
2. Runs `terraform destroy`
3. Saves configurations to startup-config via SSH

This ensures a clean teardown and prevents interfaces from being left in an active state.

## Adding New Modules

1. Create `modules/new-module/` directory with:
   - `<feature>.tf` or `interface_template.tf` - resource definitions
   - `variables.tf` - module inputs (device or interface maps)
   - `versions.tf` - provider version constraints

2. Add module call in `main.tf`:
```hcl
module "new_module" {
  source  = "./modules/new-module"
  routers = local.routers  # or wan_interfaces = local.wan_interfaces
}
```

3. Add to `depends_on` in `iosxe_save_config` resource to ensure configs are saved

**Pattern**: Modules iterate with `for_each` over maps, using device name (`each.key`) as the `device` parameter.

## Learn More

Full walkthrough and deep dive available at [netcask.com](https://netcask.com)

## License

MIT License - See [LICENSE](LICENSE) for details

---

**Part of the netcask.com network automation series**