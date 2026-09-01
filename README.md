# Floci-AZ Terraform Labs

This folder contains Terraform labs that run against Floci-AZ, a local Azure-compatible emulator. The labs do not require an Azure subscription and should not create resources in Azure.

## Requirements

Install the following tools:

- Docker Desktop with Docker Compose
- Terraform
- Git
- Windows PowerShell 5.1 or PowerShell 7
- Floci UI, cloned locally as described below

Verify the command-line tools:

```powershell
docker --version
docker compose version
terraform version
git --version
```

Docker Desktop must be running before starting the emulator.

## Folder layout

Keep `floci-ui` beside the lab directories:

```text
Labs/
|-- README.md
|-- .gitignore
|-- floci-ui/
`-- lab01/
```

The entire `floci-ui/` directory is ignored by the parent `.gitignore`. It is an independently versioned upstream project and a runtime requirement, not source code belonging to these labs.

## Install Floci UI

From the `Labs` directory:

```powershell
git clone https://github.com/floci-io/floci-ui.git
cd .\floci-ui
```

Create `docker-compose.override.yml` in `floci-ui` with the following content:

```yaml
services:
  floci-az:
    environment:
      FLOCI_AZ_TLS_ENABLED: "true"
      FLOCI_AZ_HOSTNAME: "floci-az"
      FLOCI_AZ_STORAGE_MODE: "memory"
    volumes:
      - ./azure-data:/app/data

  floci-api:
    environment:
      FLOCI_AZURE_ENDPOINT: "http://floci-az:4577"
      FLOCI_AZURE_ACCOUNT_NAME: "lab01storage001"
```

Docker Compose automatically merges this override with the upstream `docker-compose.yml` in the same directory. The override exists so the upstream clone remains mostly unchanged while the lab adds its local Azure-specific settings:

- `FLOCI_AZ_TLS_ENABLED` enables Floci-AZ's TLS endpoint, which AzureRM needs for metadata discovery.
- `FLOCI_AZ_HOSTNAME` sets the hostname used by the emulator-generated certificate inside the Compose network.
- `FLOCI_AZ_STORAGE_MODE=memory` keeps emulated Azure resources ephemeral; restarting or recreating the service may remove them.
- `./azure-data:/app/data` preserves Floci-AZ runtime data such as generated TLS material on the host.
- `FLOCI_AZURE_ENDPOINT` tells the API container to reach Floci-AZ by its Compose service name. This is an internal container-to-container URL, so it remains HTTP.
- `FLOCI_AZURE_ACCOUNT_NAME` supplies the storage account name expected by the UI integration for this lab.

Start only the services required by Lab 01:

```powershell
docker compose --profile multicloud up -d --build floci-az floci-api floci-ui
docker compose ps
```

Check the emulator and API connection:

```powershell
Invoke-RestMethod http://localhost:4577/_floci/health
Invoke-RestMethod http://localhost:4501/api/clouds/azure/status
```

The UI is available at <http://localhost:4500>.

## Trust the Floci-AZ certificate

The AzureRM provider performs metadata discovery over HTTPS at `localhost:4577`. Floci-AZ generates a self-signed certificate, so Windows does not trust it automatically.

Download the currently active certificate while Floci-AZ is running:

```powershell
Invoke-WebRequest `
  -Uri http://localhost:4577/_floci/tls-cert `
  -OutFile .\floci-az.crt
```

Import it into the trusted root store for the current Windows user:

```powershell
Import-Certificate `
  -FilePath .\floci-az.crt `
  -CertStoreLocation Cert:\CurrentUser\Root
```

This does not trust the certificate machine-wide and normally does not require an elevated PowerShell session. The downloaded `floci-az.crt` is local generated material and is ignored by Git.

If Floci-AZ regenerates its TLS files, download and import the new certificate again. Only trust a certificate obtained from the local emulator you started.

## Run Lab 01

Continue with [`lab01/README-Floci-AZ-Lab01.md`](lab01/README-Floci-AZ-Lab01.md) for the Terraform workflow, verification commands, cleanup, and troubleshooting.
