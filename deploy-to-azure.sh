#!/bin/bash
# Azure CLI commands to containerize the MCP server application, 
# push it to an existing Azure Container Registry,
# and deploy it as an Azure Container Instance

# -----------------------------------
# Parse command line arguments
# -----------------------------------
if [ $# -lt 3 ]; then
    echo "Usage: $0 <acr-name> <resource-group> <tag>"
    echo "Example: $0 myacr myresourcegroup v1.0.0"
    exit 1
fi

ACR_NAME=$1
RESOURCE_GROUP=$2
IMAGE_TAG=$3
LOCATION="westeurope"  # Default location

# -----------------------------------
# CONFIGURATION - Other settings
# -----------------------------------
# Container details
IMAGE_NAME="mcp-test-server"  # Name for your container image
CONTAINER_NAME="mcp-test-server"  # Name for your container instance
# Create DNS label by replacing dots with dashes (Azure DNS labels can't contain dots)
CLEAN_TAG=$(echo $IMAGE_TAG | tr '.' '-')
DNS_LABEL="mcpserver-$CLEAN_TAG"  # DNS label for container instance (must be unique)

# Container configuration
PORT=3000  # Port the MCP server listens on
CPU_CORES=0.25  # Number of CPU cores for the container instance
MEMORY_GB=1  # Memory in GB for the container instance

echo "Using Azure Container Registry: $ACR_NAME"
echo "Using Resource Group: $RESOURCE_GROUP"
echo "Using Image Tag: $IMAGE_TAG"
echo "Using Location: $LOCATION"
echo "Using DNS Label: $DNS_LABEL"

# -----------------------------------
# Note: Using the Dockerfile that's already in the project root
# -----------------------------------
echo "Using existing Dockerfile."

# -----------------------------------
# Check if image with tag already exists in ACR
# -----------------------------------
ACR_REGISTRY="$ACR_NAME.azurecr.io"
FULL_IMAGE_NAME="$ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

# Check if the image with this tag already exists
echo "Checking if image $FULL_IMAGE_NAME already exists in ACR..."
IMAGE_EXISTS=$(az acr repository show-tags --name $ACR_NAME --repository $IMAGE_NAME --output tsv 2>/dev/null | grep -w "^$IMAGE_TAG$" || true)

if [ -n "$IMAGE_EXISTS" ]; then
    echo "Image with tag $IMAGE_TAG already exists in ACR. Skipping build step."
else
    echo "Image with tag $IMAGE_TAG does not exist. Building image in ACR..."
    
    # Use ACR Tasks to build the image directly in ACR
    az acr build --registry $ACR_NAME --image $IMAGE_NAME:$IMAGE_TAG .
fi

echo "Tagging Docker image..."
# No need to tag, already done by ACR build

echo "Pushing image to ACR..."
# No need to push, already done by ACR build

# -----------------------------------
# Create or ensure resource group exists
# -----------------------------------
echo "Ensuring resource group exists..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# -----------------------------------
# Create an Azure Container Instance
# -----------------------------------
echo "Creating Azure Container Instance..."
az container create \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_NAME \
  --image $FULL_IMAGE_NAME \
  --cpu $CPU_CORES \
  --memory $MEMORY_GB \
  --registry-login-server $ACR_REGISTRY \
  --registry-username $(az acr credential show --name $ACR_NAME --query username -o tsv) \
  --registry-password $(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv) \
  --ports $PORT \
  --ip-address Public \
  --dns-name-label $DNS_LABEL \
  --location $LOCATION \
  --environment-variables NODE_ENV=production \
  --os-type Linux \
  --restart-policy Always

# -----------------------------------
# Show the Container Instance details
# -----------------------------------
echo "Retrieving Container Instance details..."
az container show \
  --resource-group $RESOURCE_GROUP \
  --name $CONTAINER_NAME \
  --query "{FQDN:ipAddress.fqdn, IP:ipAddress.ip, Port:ipAddress.ports[0].port, ProvisioningState:provisioningState}" \
  --output table

echo "----------------------------------------------------"
echo "MCP Server is now containerized and deployed to Azure"
echo "----------------------------------------------------"
echo "To access the MCP server, use: http://$DNS_LABEL.$LOCATION.azurecontainer.io:$PORT/mcp"
echo "To check the health endpoint: http://$DNS_LABEL.$LOCATION.azurecontainer.io:$PORT/health"
echo "----------------------------------------------------"
echo "To view container logs:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "----------------------------------------------------"
echo "To delete the container when you're done:"
echo "az container delete --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME --yes"
echo "----------------------------------------------------"