#!/bin/bash

# start-backend.sh for WSL / Linux environments

REBUILD=false
RESET_DATA=false

# Parse arguments
for arg in "$@"
do
    case $arg in
        --rebuild|-Rebuild)
        REBUILD=true
        shift
        ;;
        --reset-data|-ResetData)
        RESET_DATA=true
        shift
        ;;
    esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_DIR="${PROJECT_ROOT}/infra/docker"

echo -e "\e[36mStarting AI Emotion backend stack...\e[0m"
echo -e "\e[90mTip: first-time use can take a few minutes while Docker downloads images.\e[0m"

# Ensure docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo -e "\e[31mError: Docker daemon is not running. Please start it using 'sudo service docker start' in WSL.\e[0m"
    exit 1
fi

cd "$COMPOSE_DIR" || exit 1

if [ "$RESET_DATA" = true ]; then
    echo -e "\e[33mResetting containers and volumes...\e[0m"
    docker compose down -v --remove-orphans
fi

if [ "$REBUILD" = true ]; then
    echo -e "\e[33mRebuilding images...\e[0m"
fi

docker compose up -d --build

echo -e "\e[33mBackend containers started.\e[0m"
echo -e "\e[32mUseful URLs:\e[0m"
echo -e "\e[90m  API:       http://localhost:8080\e[0m"
echo -e "\e[90m  Postgres:  localhost:5432\e[0m"
echo -e ""
echo -e "\e[33mIf you need to reinitialize the database, run:\e[0m"
echo -e "\e[90m  ./scripts/start-backend.sh --reset-data --rebuild\e[0m"
