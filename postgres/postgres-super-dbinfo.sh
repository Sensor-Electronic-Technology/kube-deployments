#!/usr/bin/env bash

# Set default values if arguments are missing
CLUSTER_NAME="${1:-marten-cluster}"
NAMESPACE="${2:-epi-system}"

SECRET_NAME="${CLUSTER_NAME}-superuser"

echo "========================================="
echo " Fetching SUPERUSER Credentials"
echo " Cluster:   $CLUSTER_NAME"
echo " Namespace: $NAMESPACE"
echo "========================================="

# Check if secret exists before trying to decode
if ! microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo "Error: Superuser secret '$SECRET_NAME' not found in namespace '$NAMESPACE'."
    exit 1
fi

# Extract and decode superuser credentials
SU_USER=$(microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.username}" | base64 --decode)
SU_PASS=$(microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.password}" | base64 --decode)

# Output results
echo "Superuser Name: $SU_USER"
echo "Password:       $SU_PASS"
echo "========================================="
