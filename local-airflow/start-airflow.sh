#!/bin/bash

# Start Airflow with proper environment variable loading
# This script sources the parent directory's .env file and starts Airflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting Airflow with Environment Variables${NC}"

# Check if parent .env file exists
PARENT_ENV_FILE="../.env"
if [ -f "$PARENT_ENV_FILE" ]; then
    echo -e "${GREEN}✅ Loading environment variables from $PARENT_ENV_FILE${NC}"

    # Export all variables from .env file
    set -a
    source "$PARENT_ENV_FILE"
    set +a

    # Validate critical environment variables
    if [ -z "$AIRFLOW_FERNET_KEY" ]; then
        echo -e "${RED}❌ ERROR: AIRFLOW_FERNET_KEY is not set${NC}"
        echo -e "${YELLOW}💡 Please check your .env file and ensure AIRFLOW_FERNET_KEY is defined${NC}"
        exit 1
    fi

    if [ -z "$MLFLOW_TRACKING_URI" ]; then
        echo -e "${YELLOW}⚠️  WARNING: MLFLOW_TRACKING_URI is not set, using default${NC}"
        export MLFLOW_TRACKING_URI="http://localhost:5000"
    fi

    # Set default values for Docker Compose
    export POSTGRES_USER="${POSTGRES_USER:-airflow}"
    export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-airflow}"
    export POSTGRES_DB="${POSTGRES_DB:-airflow}"
    export AIRFLOW_ADMIN_PASSWORD="${AIRFLOW_ADMIN_PASSWORD:-airflow}"
    export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-1}"

    echo -e "${GREEN}✅ Environment variables loaded successfully${NC}"
    echo -e "${GREEN}   - MLFLOW_TRACKING_URI: $MLFLOW_TRACKING_URI${NC}"
    echo -e "${GREEN}   - POSTGRES_USER: $POSTGRES_USER${NC}"
    echo -e "${GREEN}   - POSTGRES_DB: $POSTGRES_DB${NC}"
    echo -e "${GREEN}   - AIRFLOW_FERNET_KEY: ${AIRFLOW_FERNET_KEY:0:20}...${NC}"

else
    echo -e "${RED}❌ ERROR: .env file not found at $PARENT_ENV_FILE${NC}"
    echo -e "${YELLOW}💡 Please create a .env file in the project root directory${NC}"
    echo -e "${YELLOW}   You can use: cp ../.env.template ../.env${NC}"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ ERROR: Docker is not running${NC}"
    echo -e "${YELLOW}💡 Please start Docker and try again${NC}"
    exit 1
fi

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ ERROR: docker-compose.yml not found${NC}"
    echo -e "${YELLOW}💡 Please run this script from the local-airflow directory${NC}"
    exit 1
fi

# Create necessary directories
mkdir -p {dags,logs,plugins,config,data}

echo -e "${GREEN}🔧 Starting Docker Compose...${NC}"

# Start Docker Compose with environment variables
docker-compose up -d

# Check if services started successfully
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Airflow started successfully!${NC}"
    echo -e "${GREEN}🌐 Access Airflow at: http://localhost:8080${NC}"
    echo -e "${GREEN}   Username: airflow${NC}"
    echo -e "${GREEN}   Password: $AIRFLOW_ADMIN_PASSWORD${NC}"
    echo ""
    echo -e "${YELLOW}📋 To check logs: docker-compose logs -f${NC}"
    echo -e "${YELLOW}🛑 To stop: docker-compose down${NC}"
else
    echo -e "${RED}❌ ERROR: Failed to start Airflow${NC}"
    echo -e "${YELLOW}💡 Check Docker logs: docker-compose logs${NC}"
    exit 1
fi
