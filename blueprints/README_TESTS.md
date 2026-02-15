# Blueprint module tests

Each blueprint module includes Terraform native tests (`.tftest.hcl`) that run with `command = plan` so no Azure resources are created. Run them from the module directory.

## Run tests

**00-init** (no provider, no Azure needed):

```powershell
cd blueprints\00-init
terraform init -input=false
terraform test
```

**01-storage** (azurerm provider; plan-only, no credentials required for plan):

```powershell
cd blueprints\01-storage
terraform init -input=false
terraform test
```

**02-keyvault** (azurerm + AVM Key Vault module; plan-only):

```powershell
cd blueprints\02-keyvault
terraform init -input=false
terraform test
```

## Run all module tests (PowerShell)

```powershell
foreach ($dir in "00-init","01-storage","02-keyvault") {
  Push-Location "blueprints\$dir"
  terraform init -input=false 2>$null; terraform test
  Pop-Location
}
```

## Requirements

- Terraform >= 1.6.0
- For 01-storage and 02-keyvault: `terraform init` downloads the Azure provider (and the Key Vault module for 02-keyvault). Tests use `command = plan` only, so Azure credentials are not required for the tests to pass.
