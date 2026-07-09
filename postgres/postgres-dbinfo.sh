#!/usr/bin/env bash

# Set default values if arguments are missing
CLUSTER_NAME="${1:-marten-cluster}"
NAMESPACE="${2:-epi-system}"

SECRET_NAME="${CLUSTER_NAME}-app"

echo "========================================="
echo " Fetching Credentials for CloudNativePG"
echo " Cluster:   $CLUSTER_NAME"
echo " Namespace: $NAMESPACE"
echo "========================================="

# Check if secret exists before trying to decode
if ! microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &> /dev/null; then
    echo "Error: Secret '$SECRET_NAME' not found in namespace '$NAMESPACE'."
    exit 1
fi

# Extract and decode credentials
DB_USER=$(microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.username}" | base64 --decode)
DB_PASS=$(microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.password}" | base64 --decode)
DB_NAME=$(microk8s kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath="{.data.dbname}" | base64 --decode)

# Output results
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
echo "Database: $DB_NAME"
echo "========================================="
