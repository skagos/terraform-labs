# Floci-AZ Terraform Labs

This folder contains Terraform labs that run against Floci-AZ, a local Azure-compatible emulator. The labs do not require an Azure subscription and should not create resources in Azure.

## Requirements

Install the following tools:

- Docker Desktop with Docker Compose
- Terraform
- Git
- Windows PowerShell 5.1 or PowerShell 7
- Floci UI, cloned locally as described below

```powershell
docker --version
docker compose version
terraform version
git --version
```

Docker Desktop must be running.

## Repository structure

Keep `floci-ui` beside the lab directories:

```text
Labs/
|-- README.md
|-- .gitignore
|-- floci-ui/
`-- lab01/
```

`floci-ui/` is an independently versioned upstream runtime dependency. The parent repository ignores it except for the lab-specific Compose override.

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

Docker Compose merges this with upstream `docker-compose.yml`. It enables TLS, uses the Compose hostname, keeps resources ephemeral, persists generated runtime data, connects the API internally over HTTP, and supplies Lab 01's storage account name.

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

This current-user trust normally needs no elevation. Git ignores the generated certificate. If Floci-AZ regenerates TLS files, download and import the new certificate; trust only your local emulator's certificate.

## Run Lab 01

Continue with [`lab01/README-Floci-AZ-Lab01.md`](lab01/README-Floci-AZ-Lab01.md) for the Terraform workflow, verification commands, cleanup, and troubleshooting.
