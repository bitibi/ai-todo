#!/bin/bash

# Todo API Deployment Script for Google Cloud Run
#
# Usage: ./deploy.sh [OPTIONS]
# Options:
#   --silent          Skip interactive prompts (rebuild=yes, deploy=yes)
#   --no-rebuild      Skip Docker rebuild, use existing image
#   --rebuild         Force rebuild Docker image (default)
#   --help            Show this help message

set -e

SILENT=false
REBUILD=y

while [[ $# -gt 0 ]]; do
    case $1 in
        --silent)     SILENT=true;  shift ;;
        --no-rebuild) REBUILD=n;    shift ;;
        --rebuild)    REBUILD=y;    shift ;;
        --help)
            echo "Todo API Deployment Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --silent          Skip interactive prompts (rebuild=yes, deploy=yes)"
            echo "  --no-rebuild      Skip Docker rebuild, use existing image"
            echo "  --rebuild         Force rebuild Docker image (default)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ------------------------------------------------------------------
# Configuration — EDIT THESE BEFORE FIRST DEPLOY
# ------------------------------------------------------------------
PROJECT_ID="todo-project-493915"
REGION="us-central1"
SERVICE_NAME="todo-api"
ARTIFACT_REGISTRY="us-central1-docker.pkg.dev"
REPOSITORY="todo-api"
IMAGE_NAME="api"
IMAGE_TAG="latest"

# Non-secret runtime env (public values — safe in git)
SUPABASE_URL="https://lcupotwkvdzatlidqtio.supabase.co"
CORS_ORIGINS="http://localhost:4200"
ATTACHMENTS_BUCKET="todo-attachments"

# ------------------------------------------------------------------
IMAGE_PATH="${ARTIFACT_REGISTRY}/${PROJECT_ID}/${REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "========================================"
echo "Todo API Deployment"
echo "========================================"
echo "Project: ${PROJECT_ID}"
echo "Region:  ${REGION}"
echo "Service: ${SERVICE_NAME}"
echo "Image:   ${IMAGE_PATH}"
echo "========================================"
echo ""

if [[ "$PROJECT_ID" == "REPLACE_ME_"* ]]; then
    echo "ERROR: Edit PROJECT_ID and the REPLACE_ME_* values at the top of deploy.sh before running."
    exit 1
fi

if [ "$SILENT" = false ]; then
    read -p "Deploy to production? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
else
    echo "Silent mode: proceeding."
fi

echo ""
if [ "$SILENT" = false ]; then
    read -p "Rebuild Docker image? (y/n) [y]: " -n 1 -r
    echo
    REBUILD=${REPLY:-y}
else
    echo "Silent mode: REBUILD=$REBUILD"
fi

if [[ $REBUILD =~ ^[Yy]$ ]] || [[ -z $REBUILD ]]; then
    echo "Step 1: Building Docker image..."
    gcloud.cmd builds submit --tag ${IMAGE_PATH} \
      --project ${PROJECT_ID} \
      --region ${REGION}
else
    echo "Step 1: Skipping build, using existing image..."
fi

echo ""
echo "Step 2: Deploying to Cloud Run..."
gcloud.cmd run deploy ${SERVICE_NAME} \
  --image ${IMAGE_PATH} \
  --platform managed \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,DEBUG=False,SUPABASE_URL=${SUPABASE_URL},CORS_ORIGINS=${CORS_ORIGINS},ATTACHMENTS_BUCKET=${ATTACHMENTS_BUCKET}" \
  --update-secrets "SUPABASE_SERVICE_KEY=SUPABASE_SERVICE_KEY:latest,OPENAI_API_KEY=OPENAI_API_KEY:latest" \
  --memory 512Mi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 5 \
  --min-instances 0

echo ""
echo "========================================"
echo "Deployment completed successfully!"
echo "========================================"

SERVICE_URL=$(gcloud.cmd run services describe ${SERVICE_NAME} \
  --platform managed \
  --region ${REGION} \
  --project ${PROJECT_ID} \
  --format 'value(status.url)')

echo ""
echo "Service URL: ${SERVICE_URL}"
echo ""
echo "Smoke test:"
echo "  curl ${SERVICE_URL}/"
echo "  curl ${SERVICE_URL}/health"
