ENV_FILE := .env
DOCKER_COMPOSE := docker compose

# Definizione dei colori ANSI
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Load variables from the .env file if it exists
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export $(shell sed 's/=.*//' $(ENV_FILE))
endif


.PHONY: start build build-debug docker-clean enter stop logs pull prepare uninstall

# Target to start the containers
start:
	@echo "Restarting $(DOCKER_COMPOSE) containers..."
	$(DOCKER_COMPOSE) up --remove-orphans -d

# Target to enter the container
enter:
	@if [ -z "${SERVICE_NAME}" ]; then \
	    echo "$(RED)Error: SERVICE_NAME is not set. Please define it in your environment or .env file.$(NC)"; \
	    exit 1; \
	fi

	@echo "Entering container: ${SERVICE_NAME}..."
	$(DOCKER_COMPOSE) run --remove-orphans ${SERVICE_NAME} /bin/bash

# Target to stop and remove the containers
stop:
	@echo "Stopping and removing $(DOCKER_COMPOSE) containers..."
	$(DOCKER_COMPOSE) down
	$(DOCKER_COMPOSE) rm -f

# Target to follow the container logs
logs:
	@echo "Displaying container logs..."
	$(DOCKER_COMPOSE) logs -f

# Target to pull the images
pull:
	@echo "Pulling images..."
	$(DOCKER_COMPOSE) pull

# Target to prepare the environment (e.g., pulling the latest images)
prepare:
	@echo "Preparing environment..."
	$(DOCKER_COMPOSE) pull
	
# Target to uninstall: stop containers, remove them, and delete all images and volumes
uninstall:
	@echo "Uninstalling..."
	$(DOCKER_COMPOSE) down && $(DOCKER_COMPOSE) rm -f
	$(DOCKER_COMPOSE) down --rmi all --volumes
	
build:
	@echo "Image build"
	docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
	@echo "Image built: ${IMAGE_NAME}:${IMAGE_TAG}"
	
build-debug:
	@echo "Image build"
	docker build --progress=plain -t ${IMAGE_NAME}:${IMAGE_TAG} .
	@echo "Image built: ${IMAGE_NAME}:${IMAGE_TAG}"

docker-clean:
	@docker builder prune -f
	@docker system prune -f

help:
	@echo "Available targets:"
	@echo "  start           - Restart Docker Compose containers"
	@echo "  enter           - Enter a specific container (SERVICE_NAME must be set)"
	@echo "  build           - build image"
	@echo "  build-debug     - build image with --progress=plain option"
	@echo "  docker-clean    - Exec docker builder prune + docker system prune -f"
	@echo "  stop            - Stop and remove Docker Compose containers"
	@echo "  logs            - Follow container logs"
	@echo "  pull            - Pull the latest images"
	@echo "  prepare         - Prepare the environment by pulling images"
	@echo "  uninstall       - Remove containers, images, and volumes"

test:
	@echo "--------------------------------------------------"
	@echo "Test /public endpoint"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/public); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s http://localhost:8080/public; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /basic endpoint con credenziali valide"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -u $$(cat secrets/basic_auth_username.txt):$$(cat secrets/basic_auth_password.txt) http://localhost:8080/basic); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -u $$(cat secrets/basic_auth_username.txt):$$(cat secrets/basic_auth_password.txt) http://localhost:8080/basic; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /basic endpoint con credenziali NON valide"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -u wrong:wrong http://localhost:8080/basic); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -u wrong:wrong http://localhost:8080/basic; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /token endpoint con token valido"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $$(cat secrets/my_token.txt)" http://localhost:8080/token); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -H "Authorization: Bearer $$(cat secrets/my_token.txt)" http://localhost:8080/token; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /token endpoint con token NON valido"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer invalidtoken" http://localhost:8080/token); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -H "Authorization: Bearer invalidtoken" http://localhost:8080/token; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /apikey endpoint con API Key valida"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: $$(cat secrets/my_api_key.txt)" http://localhost:8080/apikey); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -H "X-API-Key: $$(cat secrets/my_api_key.txt)" http://localhost:8080/apikey; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /apikey endpoint con API Key NON valida"
	@echo "--------------------------------------------------"
	@STATUS_CODE=$$(curl -s -o /dev/null -w "%{http_code}" -H "X-API-Key: wrongapikey" http://localhost:8080/apikey); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi
	@curl -s -H "X-API-Key: wrongapikey" http://localhost:8080/apikey; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /generate-jwt: generazione del token JWT"
	@echo "--------------------------------------------------"
	@curl -s http://localhost:8080/generate-jwt > generated_jwt.txt
	@echo "JWT generato e salvato in 'generated_jwt.txt':"
	@cat generated_jwt.txt; echo "\n"

	@echo "--------------------------------------------------"
	@echo "Test /jwt endpoint utilizzando il token JWT generato"
	@echo "--------------------------------------------------"
	@JWT=$$(sed -n 's/.*"message":"\([^"]*\)".*/\1/p' generated_jwt.txt); \
	echo "JWT usato: $$JWT"; \
	RESPONSE=$$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $$JWT" http://localhost:8080/jwt); \
	STATUS_CODE=$$(echo "$$RESPONSE" | tail -n1); \
	BODY=$$(echo "$$RESPONSE" | sed '$$d'); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi; \
	echo "$$BODY"; echo "\n"
	@rm generated_jwt.txt

	@echo "--------------------------------------------------"
	@echo "Test /jwt endpoint con token JWT NON valido"
	@echo "--------------------------------------------------"
	@INVALID_JWT="invalid.jwt.token"; \
	echo "JWT usato: $$INVALID_JWT"; \
	RESPONSE=$$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $$INVALID_JWT" http://localhost:8080/jwt); \
	STATUS_CODE=$$(echo "$$RESPONSE" | tail -n1); \
	BODY=$$(echo "$$RESPONSE" | sed '$$d'); \
	if [ $$STATUS_CODE -eq 200 ]; then \
		echo "${GREEN}200 OK${NC}"; \
	elif [ $$STATUS_CODE -eq 401 ]; then \
		echo "${YELLOW}401 Unauthorized${NC}"; \
	elif [ $$STATUS_CODE -eq 500 ]; then \
		echo "${RED}500 Internal Server Error${NC}"; \
	else \
		echo "Codice di stato sconosciuto: $$STATUS_CODE"; \
	fi; \
	echo "$$BODY"; echo "\n"