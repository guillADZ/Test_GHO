export IDENTITY_CLIENT_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query clientId -otsv)"
export IDENTITY_RESOURCE_ID="$(az identity show -g ${IDENTITY_RESOURCE_GROUP} -n ${IDENTITY_NAME} --query id -otsv)"
export RG_RESOURCE_ID="$(az group show -g ${RESOURCE_GROUP} --query id -otsv)"
export NODE_GROUP=$(az aks show -g ${RESOURCE_GROUP} -n ${CLUSTER_NAME} --query nodeResourceGroup -o tsv)
export NODES_RESOURCE_ID=$(az group show -n $NODE_GROUP -o tsv --query "id")

az role assignment create --role "Reader" --assignee "$IDENTITY_CLIENT_ID" --scope $NODES_RESOURCE_ID
az role assignment create --role "acrpull" --assignee "$IDENTITY_CLIENT_ID" --scope $RG_RESOURCE_ID
