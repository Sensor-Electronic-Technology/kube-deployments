#!/bin/bash

set -e

# Default cluster name if no argument is provided
CLUSTER_NAME="marten-cluster"

# Parse optional input parameter (-d <database_cluster_name>)
while getopts "d:" opt; do
  case ${opt} in
    d )
      CLUSTER_NAME=$OPTARG
      ;;
    \? )
      echo "Usage: $0 [-d database_cluster_name]"
      exit 1
      ;;
  esac
done

SERVICE_NAME="${CLUSTER_NAME}-lb"

echo "===================================================="
echo " WARNING: This will permanently delete database data!"
echo "===================================================="
echo "Target Cluster Name: $CLUSTER_NAME"
echo "Target Service Name: $SERVICE_NAME"
echo "----------------------------------------------------"

# Confirmation Prompt
read -p "Are you sure you want to delete this cluster and all its data? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Cleanup canceled. No changes were made."
    exit 0
fi

echo ""
echo "=== Starting PostgreSQL Cluster Cleanup ==="

# 1. Delete the LoadBalancer Service
if microk8s kubectl get service "$SERVICE_NAME" &>/dev/null; then
    echo "Deleting LoadBalancer service: $SERVICE_NAME..."
    microk8s kubectl delete service "$SERVICE_NAME"
else
    echo "Service $SERVICE_NAME not found. Skipping."
fi

# 2. Delete the CloudNativePG Cluster
if microk8s kubectl get cluster.postgresql.cnpg.io "$CLUSTER_NAME" &>/dev/null; then
    echo "Deleting CloudNativePG cluster: $CLUSTER_NAME..."
    microk8s kubectl delete cluster.postgresql.cnpg.io "$CLUSTER_NAME"
else
    echo "Cluster $CLUSTER_NAME not found. Skipping."
fi

# 3. Delete generated app and superuser secrets
echo "Deleting generated application and superuser secrets..."
microk8s kubectl delete secret "${CLUSTER_NAME}-app" "${CLUSTER_NAME}-superuser" --ignore-not-found

# 4. Find and delete all Persistent Volume Claims (PVCs) matching the cluster name
echo "Searching for persistent data volumes (PVCs) associated with $CLUSTER_NAME..."
PVCS=$(microk8s kubectl get pvc -o jsonpath="{.items[?(@.metadata.labels['cnpg\.io/cluster']=='$CLUSTER_NAME')].metadata.name}")

if [ -n "$PVCS" ]; then
    echo "Deleting PVCs: $PVCS"
    set +e  # Disable exit-on-error temporarily in case a PVC is already being deleted
    microk8s kubectl delete pvc $PVCS
    set -e
else
    echo "No matching data volumes (PVCs) found."
fi

echo "=== Cleanup Complete ==="
