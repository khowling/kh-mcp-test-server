#!/bin/bash
# Script to build a new version of the MCP server container locally,
# push it to Azure Container Registry, and update an existing container instance

# -----------------------------------
# Parse command line arguments
# -----------------------------------
if [ $# -lt 3 ]; then
    echo "Usage: $0 <acr-name> <resource-group> <tag>"
    echo "Example: $0 myacr myresourcegroup 0.6"
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

CLEAN_TAG=$(echo $IMAGE_TAG | tr '.' '-')
DNS_LABEL="mcpserver-$CLEAN_TAG"  # DNS label for container instance (must be unique)

# Container configuration
PORT=80  # Port the MCP server listens on
CPU_CORES=0.25  # Number of CPU cores for the container instance
MEMORY_GB=1  # Memory in GB for the container instance



echo "Using Azure Container Registry: $ACR_NAME"
echo "Using Resource Group: $RESOURCE_GROUP"
echo "Using Image Tag: $IMAGE_TAG"
echo "Using Location: $LOCATION"

# -----------------------------------
# Build the Docker image locally
# -----------------------------------
echo "Building Docker image locally..."
docker build -t $IMAGE_NAME:$IMAGE_TAG .

# -----------------------------------
# Tag and push the image to ACR
# -----------------------------------
ACR_REGISTRY="$ACR_NAME.azurecr.io"
FULL_IMAGE_NAME="$ACR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"

echo "Tagging Docker image as $FULL_IMAGE_NAME..."
docker tag $IMAGE_NAME:$IMAGE_TAG $FULL_IMAGE_NAME

echo "Pushing image to ACR..."
docker push $FULL_IMAGE_NAME

# -----------------------------------
# Get ACR credentials with a single call
# -----------------------------------
echo "Retrieving ACR credentials..."
# Use array query to get both values at once
ACR_CREDS=($(az acr credential show --name $ACR_NAME --query "[username, passwords[0].value]" -o tsv))
ACR_USERNAME=${ACR_CREDS[0]}
ACR_PASSWORD=${ACR_CREDS[1]}

# -----------------------------------
# Update the existing container instance
# -----------------------------------
echo "Updating container instance with new image..."

# Update the container instance with the new image
az container create \
    --resource-group $RESOURCE_GROUP \
    --name $CONTAINER_NAME \
    --image $FULL_IMAGE_NAME \
    --cpu $CPU_CORES \
    --memory $MEMORY_GB \
    --registry-login-server $ACR_REGISTRY \
    --registry-username "$ACR_USERNAME" \
    --registry-password "$ACR_PASSWORD" \
    --ports $PORT \
    --ip-address Public \
    --dns-name-label $DNS_LABEL \
    --location $LOCATION \
    --environment-variables NODE_ENV=production PORT=$PORT \
    --os-type Linux \
    --restart-policy Always



echo "----------------------------------------------------"
echo "MCP Server is now updated in Azure"
echo "----------------------------------------------------"
echo "To view container logs:"
echo "az container logs --resource-group $RESOURCE_GROUP --name $CONTAINER_NAME"
echo "----------------------------------------------------"