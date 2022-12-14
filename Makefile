.SILENT:

COLOR_RESET = \033[0m
COLOR_GREEN = \033[32m
COLOR_YELLOW = \033[33m
PROJECT_NAME = `basename $(PWD)`
USER_UID = `id -u`

VERSION = `cat VERSION`
PORT = 8888
IMAGE = "tw/$(PROJECT_NAME):$(VERSION)"

.DEFAULT_GOAL = help

## Prints this help
help:
	printf "${COLOR_YELLOW}\n${PROJECT_NAME}\n\n${COLOR_RESET}"
	awk '/^[a-zA-Z\-\_0-9\. %]+:/ { \
			helpMessage = match(lastLine, /^## (.*)/); \
			if (helpMessage) { \
					helpCommand = substr($$1, 0, index($$1, ":")); \
					helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
					printf "${COLOR_GREEN}$$ make %s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
			} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)
	printf "\n"

## Installs the project build environment
setup:
	pip3 install -r requirements.local.txt

## Run tests in Docker
test_docker: setup
	fab test

## Run tests in venv
test: setup
	fab test:env=venv

## Start a jupyter notebook instance with the project
jupyter:
	echo "Building version $(VERSION)"
	docker run -it --rm \
		-p $(PORT):8888 \
		--user $(USER_UID) --group-add users \
		-e USERNAME="jovyan" \
        -e TZ=America/Sao_Paulo \
		-v $(PWD):/home/jovyan \
		jupyter/base-notebook

## Generate a new release and tag
release:
	fab release

## Build sphinx documentation on local virtualenv
doc:
	fab doc:env=virtualenv

## Build sphinx documentation on Docker
doc_docker:
	fab doc:env=docker
