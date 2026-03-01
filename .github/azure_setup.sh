#!/bin/bash
# 1. Set variables
GITHUB_ORG="jakubikkamil"
GITHUB_REPO="ad-demo-terraform-projects"
APP_NAME="github-terraform-deployer"
ENVIRONMENT_NAME="dev"

# 2. Get subscription info
SUBSCRIPTION_ID=$(az account show --query 'id' -o tsv)
TENANT_ID=$(az account show --query 'tenantId' -o tsv)

# 3. Create app registration
#az ad app create --display-name $APP_NAME
CLIENT_ID=$(az ad app list --display-name $APP_NAME --query '[0].appId' -o tsv)
APP_ID=$(az ad app list --display-name $APP_NAME --query '[0].id' -o tsv)

# 4. Create federated credential
# az ad app federated-credential create \
#   --id $APP_ID \
#   --parameters "{
#     \"name\": \"github-$GITHUB_ORG-$GITHUB_REPO\",
#     \"issuer\": \"https://token.actions.githubusercontent.com\",
#     \"subject\": \"repo:$GITHUB_ORG/$GITHUB_REPO:environment:$ENVIRONMENT_NAME\",
#     \"audiences\": [\"api://AzureADTokenExchange\"],
#     \"description\": \"GitHub Actions\"
#   }"

# 5. Create service principal
# az ad sp create --id $CLIENT_ID

OBJECT_ID=$(az ad sp list --display-name $APP_NAME --query '[0].id' -o tsv)
# 6. Assign Owner role
az role assignment create \
  --assignee-object-id $OBJECT_ID \
  --assignee-principal-type ServicePrincipal \
  --role "Owner" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"

# 7. Display secrets
echo "AZURE_CLIENT_ID=$CLIENT_ID"
echo "AZURE_OBJECT_ID=$OBJECT_ID"
echo "AZURE_TENANT_ID=$TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID"