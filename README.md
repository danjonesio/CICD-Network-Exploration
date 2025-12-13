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
        Cisco Routers
     (P-01, P-02, DR-01, DR-02)
```

## Prerequisites

- Cisco IOS devices with NETCONF enabled
- Drone CI/CD server
- MinIO for state storage
- Terraform >= 1.0

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
drone secret add --repository your-org/Network-CICD --name MINIO_BUCKET --data "drone-artifacts"
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
export TF_VAR_username="admin"
export TF_VAR_password="cisco"

terraform init -backend-config="endpoints={s3=\"http://minio:9000\"}" -backend-config="bucket=drone-artifacts"
terraform apply
```

## Project Structure

```
Network-CICD/
├── main.tf              # Provider & module configuration
├── backend.tf           # Remote state configuration
├── devices.tf           # Device inventory
├── variables.tf         # Input variables
├── .drone.yml           # CI/CD pipeline
├── destroy.sh           # Cleanup script
└── modules/
    ├── snmp/            # SNMP configuration
    └── banner/          # Login banner configuration
```

## Available Modules

### SNMP
Configures SNMP communities, location, contact, and chassis ID.

### Banner
Applies login warning banners to devices.

## Destroying Configuration

```bash
chmod +x destroy.sh
./destroy.sh
```

The script removes all configurations and saves to startup-config. This is run locally to avoid any confusion in pipelines.

## Adding New Modules

1. Create `modules/new-module/` directory
2. Add `main.tf`, `variables.tf`, `versions.tf`
3. Reference in [`main.tf`](main.tf ):

```hcl
module "new_module" {
  source  = "./modules/new-module"
  routers = local.routers
}
```

## Learn More

Full walkthrough and deep dive available at [netcask.com](https://netcask.com)

## License

MIT License - See [LICENSE](LICENSE) for details

---

**Part of the netcask.com network automation series**