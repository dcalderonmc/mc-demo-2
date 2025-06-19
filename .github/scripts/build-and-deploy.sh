#!/bin/bash

set -e

# Default values
ENVIRONMENT=""
VERCEL_TOKEN=""
DB_URL=""
VERCEL_ORG_ID=""
VERCEL_PROJECT_ID=""
BRANCH=""
BASE_URL=""
PULL_REQUEST_NUMBER=""

# Help message
usage() {
  echo "Usage: $0 --environment <environment> --token <vercel_token> --database <db_url> --org-id <vercel_org_id> --project-id <vercel_project_id> [--branch <branch_name>] [--base-url <base_url>] [--pr-number <pull_request_number>]"
  echo "  --environment    Environment (e.g., preview, production, development)"
  echo "  --token         Vercel Token"
  echo "  --database      Database URL"
  echo "  --org-id        Vercel Organization ID"
  echo "  --project-id    Vercel Project ID"
  echo "  --branch        Branch name (optional)"
  echo "  --base-url      Base URL (optional)"
  echo "  --pr-number     Pull Request Number (optional)"
  exit 1
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
  case $1 in
    --environment) ENVIRONMENT="$2"; shift 2 ;;
    --token) VERCEL_TOKEN="$2"; shift 2 ;;
    --database) DB_URL="$2"; shift 2 ;;
    --org-id) VERCEL_ORG_ID="$2"; shift 2 ;;
    --project-id) VERCEL_PROJECT_ID="$2"; shift 2 ;;
    --branch) BRANCH="$2"; shift 2 ;;
    --base-url) BASE_URL="$2"; shift 2 ;;
    --pr-number) PULL_REQUEST_NUMBER="$2"; shift 2 ;;
    *) echo "Unknown parameter: $1"; usage ;;
  esac
done

# Check for required arguments
if [[ -z "$ENVIRONMENT" || -z "$VERCEL_TOKEN" || -z "$DB_URL" || -z "$VERCEL_ORG_ID" || -z "$VERCEL_PROJECT_ID" ]]; then
  echo "Error: Missing required arguments."
  usage
fi

# Set environment variables for Vercel
export VERCEL_ORG_ID
export VERCEL_PROJECT_ID

# Install Dependencies
echo "Installing dependencies..."
pnpm install --frozen-lockfile

# Create .env file with DB Credentials
echo "Setting up environment variables..."
echo "DATABASE_URL=$DB_URL" > .env
if [[ -n "$BRANCH" ]]; then
  echo "BRANCH=$BRANCH" >> .env
fi
if [[ -n "$BASE_URL" ]]; then
  echo "NEXT_PUBLIC_BASE_URL=$BASE_URL" >> .env
fi

# Pull Vercel Environment Information
echo "Pulling Vercel environment configuration..."
pnpm vercel pull --yes --environment="$ENVIRONMENT" --token="$VERCEL_TOKEN"

# Generate Git-related environment variables
echo "Generating Git environment variables..."
echo "VERCEL_GIT_COMMIT_SHA=$(git rev-parse HEAD)" >> .env
echo "VERCEL_GIT_COMMIT_REF=$(git rev-parse --abbrev-ref HEAD)" >> .env
echo "VERCEL_GIT_COMMIT_MESSAGE=$(git log -1 --pretty=%B)" >> .env
echo "VERCEL_GIT_COMMIT_AUTHOR_NAME=$(git log -1 --pretty=%an)" >> .env
echo "VERCEL_GIT_COMMIT_AUTHOR_LOGIN=$(git log -1 --pretty=%ae)" >> .env
echo "VERCEL_GIT_PROVIDER=github" >> .env
echo "VERCEL_GIT_PREVIOUS_SHA=$(git rev-parse HEAD^1)" >> .env
echo "VERCEL_GIT_REPO_OWNER=$(git config --get remote.origin.url | sed -n 's/.*github.com[:/]\([^/]*\).*/\1/p')" >> .env
echo "VERCEL_GIT_REPO_SLUG=$(git config --get remote.origin.url | sed -n 's/.*\/\([^.]*\).*/\1/p')" >> .env

if [ -n "$PULL_REQUEST_NUMBER" ]; then
  echo "VERCEL_GIT_PULL_REQUEST_ID=$PULL_REQUEST_NUMBER" >> .env
fi

# Dynamically select the correct .env file based on the environment
VERCEL_ENV_FILE=".vercel/.env.$ENVIRONMENT.local"
if [[ -f "$VERCEL_ENV_FILE" ]]; then
  echo "Merging non-Git environment variables from $VERCEL_ENV_FILE"
  # Merge all non-Git variables from the Vercel env file
  grep -v "VERCEL_GIT_" "$VERCEL_ENV_FILE" >> .env
else
  echo "Error: $VERCEL_ENV_FILE not found. Skipping environment merge."
  exit 1
fi

# Build Project Artifacts
echo "Building project artifacts..."
# Enable corepack to use pnpm specified in package.json
BUILD_CMD="pnpm vercel build --token=\"$VERCEL_TOKEN\""
if [ "$ENVIRONMENT" == "production" ]; then
    BUILD_CMD+=" --prod"
fi
NODE_OPTIONS="--max_old_space_size=4096" eval $BUILD_CMD
# Determine deploy command
DEPLOY_CMD="pnpm vercel deploy --prebuilt --token=\"$VERCEL_TOKEN\""
if [ "$ENVIRONMENT" == "production" ]; then
    DEPLOY_CMD+=" --prod"
fi

# Deploy to Vercel
echo "Deploying to Vercel..."
DEPLOY_URL=$(eval $DEPLOY_CMD)

# Output the deployment URL
echo "Deployment URL: $DEPLOY_URL"
echo "preview_url=$DEPLOY_URL" >> $GITHUB_ENV
