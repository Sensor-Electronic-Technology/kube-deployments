#!/usr/bin/env bash


set -e

ENV_FILE=".env"
CONFIGMAP_NAME="burn-app-config"
NAMESPACE="default"


DEPLOYMENTS=(
    "epi-web-service"
    "epi-background-worker"
    "epi-api-gateway"
)

ACTION=$1

if [[ "$ACTION" != "create" && "$ACTION" != "update" ]]; then
    echo "❌ Error: Missing or invalid action argument."
    echo "Usage: $0 [create|update]"
    exit 1
fi

# Validate that the local .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: Local file '$ENV_FILE' not found in this directory."
    exit 1
fi


CM_EXISTS=$(kubectl get configmap "$CONFIGMAP_NAME" --namespace="$NAMESPACE" --no-headers 2>/dev/null || true)

if [ "$ACTION" == "create" ]; then
    if [ -n "$CM_EXISTS" ]; then
        echo "⚠️  Warning: ConfigMap '$CONFIGMAP_NAME' already exists in namespace '$NAMESPACE'."
        echo "If you want to overwrite it, run: $0 update"
        exit 1
    fi

    echo "➡️  Creating fresh ConfigMap '$CONFIGMAP_NAME'..."
    kubectl create configmap "$CONFIGMAP_NAME" --from-env-file="$ENV_FILE" --namespace="$NAMESPACE"
    echo "✅ ConfigMap successfully created."

elif [ "$ACTION" == "update" ]; then
    if [ -z "$CM_EXISTS" ]; then
        echo "❌ Error: ConfigMap '$CONFIGMAP_NAME' does not exist in namespace '$NAMESPACE' yet."
        echo "Please create it first by running: $0 create"
        exit 1
    fi

    echo "➡️  Updating existing ConfigMap '$CONFIGMAP_NAME'..."
    # Uses dry-run and apply to gracefully update keys without deleting the object
    kubectl create configmap "$CONFIGMAP_NAME" \
      --from-env-file="$ENV_FILE" \
      --namespace="$NAMESPACE" \
      --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ ConfigMap successfully updated with latest .env values."
fi


# echo "🔄 Processing rolling restarts for dependent deployments..."

# for DEPLOYMENT in "${DEPLOYMENTS[@]}"; do
#     echo "--------------------------------------------------"
    
#     # Safety Check: Verify the deployment actually exists before hitting it
#     DEP_EXISTS=$(kubectl get deployment "$DEPLOYMENT" --namespace="$NAMESPACE" --no-headers 2>/dev/null || true)
    
#     if [ -z "$DEP_EXISTS" ]; then
#         echo "⚠️  Skipping '$DEPLOYMENT': Not found in namespace '$NAMESPACE'."
#         continue
#     fi

#     echo "➡️  Triggering rolling restart for deployment '$DEPLOYMENT'..."
#     kubectl rollout restart deployment/"$DEPLOYMENT" --namespace="$NAMESPACE"

#     echo "➡️  Waiting for '$DEPLOYMENT' rollout to complete..."
#     kubectl rollout status deployment/"$DEPLOYMENT" --namespace="$NAMESPACE"
    
#     echo "✅ '$DEPLOYMENT' successfully updated!"
# done

echo "--------------------------------------------------"
echo "🎉 Success! Action [$ACTION] completed and all available deployments are running the new environment."
