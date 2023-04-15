# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursively expanded variables
SHELL = /usr/bin/sh
TRUTHY_VALUES = \
    true\
    1

ANSIBLE_INVENTORY_PATH = ./localhost
ANSIBLE_SRC = $(shell find . \
	\( \
		\( -type f \) \
		-and \( -name '*.yml' \) \
	\) \
	-and ! \( -name '.python-version' \) \
	-and ! \( -path '*.git*' \) \
)

YAML_SRC = \
	./.github/workflows\
	./casc.yaml\
	./.ansible-lint

DOCKER_LATEST_VERSION_TAG = $(shell ${GIT} describe --tags --abbrev=0)
export DOCKER_CONTEXT_TAG = latest
export CONTAINER_NAME = jenkins-torkel
export CONTAINER_NETWORK = jc1
export CONTAINER_VOLUME = jenkins_home:/var/jenkins_home
export DOCKER_REPO = cavcrosby/jenkins-torkel
define ANSIBLE_INVENTORY =
cat << _EOF_
all:
  hosts:
    localhost:
      email_secret:
_EOF_
endef
export ANSIBLE_INVENTORY

ifneq ($(findstring ${IMAGE_RELEASE_BUILD},${TRUTHY_VALUES}),)
	DOCKER_TARGET_IMAGES = \
		${DOCKER_REPO}:${DOCKER_CONTEXT_TAG} \
		${DOCKER_REPO}:${DOCKER_LATEST_VERSION_TAG}
else
	DOCKER_CONTEXT_TAG = test
	DOCKER_TARGET_IMAGES = \
		${DOCKER_REPO}:${DOCKER_CONTEXT_TAG}
endif

# targets
HELP = help
SETUP = setup
TEST = test
CLEAN = clean
IMAGE = image
DEPLOY = deploy
DISMANTLE = dismantle
PUBLISH = publish
LINT = lint

# executables
ANSIBLE_GALAXY = ansible-galaxy
ANSIBLE_LINT = ansible-lint
ANSIBLE_PLAYBOOK = ansible-playbook
DOCKER = docker
GAWK = gawk
GIT = git
PYTHON = python
PIP = pip
PRE_COMMIT = pre-commit
YAMLLINT = yamllint

# simply expanded variables
executables := \
	${DOCKER}\
	${GAWK}\
	${GIT}\
	${PYTHON}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Common make targets:'
>	@echo '  ${SETUP}        - installs the distro-independent dependencies for this'
>	@echo '                 project'
>	@echo '  ${IMAGE}        - creates the docker image that host Jenkins'
>	@echo '  ${DEPLOY}       - creates a container from the project image'
>	@echo '  ${DISMANTLE}    - removes a deployed container and the supporting'
>	@echo '                 environment setup'
>	@echo '  ${LINT}         - performs linting on the yaml configuration files'
>	@echo '  ${PUBLISH}      - publish docker image to the project image repository'
>	@echo '  ${TEST}         - runs test suite for the project'
>	@echo '  ${CLEAN}        - removes files generated from the configs target'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_JC_LOG_SECRETS       - toggle logging secrets from Ansible when deploying a'
>	@echo '                                 project image (e.g. false/true, or 0/1)'

.PHONY: ${SETUP}
${SETUP}:
>	eval "$${ANSIBLE_INVENTORY}" > "${ANSIBLE_INVENTORY_PATH}"
>	${PYTHON} -m ${PIP} install --upgrade "${PIP}"
>	${PYTHON} -m ${PIP} install \
		--requirement "./requirements.txt" \
		--requirement "./dev-requirements.txt"

>	${ANSIBLE_GALAXY} collection install --requirements-file "./requirements.yml"
>	${PRE_COMMIT} install

.PHONY: ${IMAGE}
${IMAGE}:
>	${DOCKER} build \
		--build-arg BRANCH="$$(${GIT} branch --show-current)" \
		--build-arg COMMIT="$$(${GIT} show --format=%h --no-patch)" \
		$(addprefix --tag=,${DOCKER_TARGET_IMAGES}) \
		.

.PHONY: ${DEPLOY}
${DEPLOY}:
>	 ${ANSIBLE_PLAYBOOK} \
		--ask-become-pass \
		--inventory "${ANSIBLE_INVENTORY_PATH}" \
		"./playbooks/create_container.yml"

.PHONY: ${DISMANTLE}
${DISMANTLE}:
>	${DOCKER} rm --force "${CONTAINER_NAME}"
>	${DOCKER} network rm --force "${CONTAINER_NETWORK}"
>	${DOCKER} volume rm --force "$$(echo "${CONTAINER_VOLUME}" \
		| ${GAWK} --field-separator ':' '{print $$1}')"

.PHONY: ${LINT}
${LINT}:
>	@for fil in ${ANSIBLE_SRC}; do \
>		if echo $${fil} | grep --quiet "-"; then \
>			echo "make: $${fil} should not contain a dash in the filename"; \
>		fi \
>	done
>	${ANSIBLE_LINT}
>	${YAMLLINT} ${YAML_SRC}

.PHONY: ${PUBLISH}
${PUBLISH}:
>	@for docker_target_image in ${DOCKER_TARGET_IMAGES}; do \
>		echo ${DOCKER} push "$${docker_target_image}"; \
>		${DOCKER} push "$${docker_target_image}"; \
>	done

.PHONY: ${TEST}
${TEST}: ${IMAGE}
>	${PYTHON} -m unittest --verbose

.PHONY: ${CLEAN}
${CLEAN}:
>	${DOCKER} rmi --force ${DOCKER_REPO}:test $$(${DOCKER} images \
		--filter label="tech.cavcrosby.jenkins.torkel.vcs-repo=https://github.com/cavcrosby/jenkins-torkel" \
		--filter dangling="true" \
		--format "{{.ID}}")
