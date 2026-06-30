#!/usr/bin/env bash
set -euo pipefail

# create_admin.sh - helper to create Firebase admin user using tools/create_admin.js
# Usage:
#   ./tools/create_admin.sh path/to/serviceAccountKey.json admin@example.com StrongPass123 [--deploy-rules]

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd)"

SERVICE_KEY="${1:-}" 
EMAIL="${2:-}"
PASSWORD="${3:-}"
DEPLOY_RULES=false
if [[ "${4:-}" == "--deploy-rules" ]]; then DEPLOY_RULES=true; fi

if ! command -v node >/dev/null 2>&1; then
  echo "Error: node not found in PATH. Install Node.js before running this script." >&2
  exit 1
fi

cd "$TOOLS_DIR"

if [[ ! -f create_admin.js ]]; then
  echo "create_admin.js not found in $TOOLS_DIR" >&2
  exit 1
fi

if [[ ! -d node_modules ]]; then
  echo "Installing node dependencies..."
  npm install
fi

read_service_key() {
  if [[ -z "$SERVICE_KEY" ]]; then
    read -rp "Path to serviceAccountKey.json: " SERVICE_KEY
  fi
  if [[ ! -f "$SERVICE_KEY" ]]; then
    echo "Service account file not found: $SERVICE_KEY" >&2
    exit 1
  fi
}

read_email() { if [[ -z "$EMAIL" ]]; then read -rp "Admin email: " EMAIL; fi }
read_password() { if [[ -z "$PASSWORD" ]]; then read -rsp "Admin password: " PASSWORD; echo; fi }

read_service_key
read_email
read_password

echo "Creating admin user $EMAIL..."
node create_admin.js "$SERVICE_KEY" "$EMAIL" "$PASSWORD"

if $DEPLOY_RULES; then
  echo "Deploying Firestore rules from project root (firestore.rules)..."
  # Assumes firebase CLI logged in and project selected
  firebase deploy --only firestore:rules || { echo "Failed to deploy rules" >&2; exit 1; }
fi

echo "Done. Admin created."
