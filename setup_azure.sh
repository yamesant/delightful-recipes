SUBSCRIPTION_NAME=$1
LOCATION=$2
RESOURCE_GROUP_NAME='rg-delightful-recipes'
STORAGE_ACCOUNT_NAME='delightfulrecipes'$(openssl rand -hex 3)
CDN_PROFILE_NAME='delightfulrecipescdn'
CDN_ENDPOINT_NAME='delightfulrecipescdnendpoint'
CUSTOM_DOMAIN_NAME='delightful-recipes'
CUSTOM_DOMAIN_HOSTNAME='delightful-recipes.try-and-trash.com'

az account set \
    --subscription $SUBSCRIPTION_NAME
az group create \
    --name $RESOURCE_GROUP_NAME \
    --location $LOCATION
az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --sku Standard_LRS \
    --location $LOCATION
az storage blob service-properties update \
    --account-name $STORAGE_ACCOUNT_NAME \
    --static-website \
    --index-document index.html \
    --auth-mode login
STATIC_WEBSITE_HOSTNAME=$(az storage account show \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $RESOURCE_GROUP_NAME \
    --query 'primaryEndpoints.web' \
    --output tsv | cut -d '/' -f 3)
az storage blob upload-batch \
    --account-name $STORAGE_ACCOUNT_NAME \
    --source './source' \
    --destination '$web'
az cdn profile create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $CDN_PROFILE_NAME \
    --sku Standard_Microsoft
az cdn endpoint create \
    --resource-group $RESOURCE_GROUP_NAME \
    --profile-name $CDN_PROFILE_NAME \
    --name $CDN_ENDPOINT_NAME \
    --origin $STATIC_WEBSITE_HOSTNAME \
    --origin-host-header $STATIC_WEBSITE_HOSTNAME
az cdn custom-domain create \
    --resource-group $RESOURCE_GROUP_NAME \
    --profile-name $CDN_PROFILE_NAME \
    --endpoint-name $CDN_ENDPOINT_NAME \
    --name $CUSTOM_DOMAIN_NAME \
    --hostname $CUSTOM_DOMAIN_HOSTNAME
az cdn custom-domain enable-https \
    --resource-group $RESOURCE_GROUP_NAME \
    --profile-name $CDN_PROFILE_NAME \
    --endpoint-name $CDN_ENDPOINT_NAME \
    --name $CUSTOM_DOMAIN_NAME
az cdn endpoint rule add \
    --resource-group $RESOURCE_GROUP_NAME \
    --profile-name $CDN_PROFILE_NAME \
    --name $CDN_ENDPOINT_NAME \
    --rule-name enforceHTTPS \
    --order 1 \
    --match-variable RequestScheme \
    --operator Equal \
    --match-values HTTP \
    --action-name UrlRedirect \
    --redirect-protocol Https \
    --redirect-type Moved