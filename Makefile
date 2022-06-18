include base.mk

# recursively expanded variables
CASC_FILE = casc.yaml
CHILD_CASC_FILE = child-casc.yaml
TEMP_CASC_FILE = temp-casc.yaml

# targets
CONFIGS = configs

define ANSIBLE_INVENTORY =
cat << _EOF_
all:
  hosts:
    localhost:
      email_secret:
_EOF_
endef
export ANSIBLE_INVENTORY

# include other generic makefiles
include docker.mk
export CONTAINER_NAME = jenkins-torkel
export CONTAINER_NETWORK = jbc1
export CONTAINER_VOLUME = jenkins_home:/var/jenkins_home
export DOCKER_REPO = cavcrosby/jenkins-torkel
DOCKER_VCS_LABEL = tech.cavcrosby.jenkins.torkel.vcs-repo=https://github.com/cavcrosby/jenkins-docker-torkel

include python.mk
# overrides defaults set by included makefiles
VIRTUALENV_PYTHON_VERSION = 3.9.5

include ansible.mk
ANSIBLE_SRC = $(shell find . \
	\( \
		\( -type f \) \
		-and \( -name '*.yml' \) \
	\) \
	-and ! \( -name '.python-version' \) \
	-and ! \( -path '*.git*' \) \
)

include yamllint.mk
YAML_SRC = \
	./.github/workflows\
	./child-casc.yaml

# executables
JCASCUTIL = jcascutil

# simply expanded variables
executables := \
	${python_executables}\
	${docker_executables}\
	${yamllint_executables}

_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${SETUP}        - installs the distro-independent dependencies for this'
>	@echo '                 project and runs the needed jcascutil setup'
>	@echo '  ${CONFIGS}      - creates/pulls the needed material to perform a docker build'
>	@echo '  ${IMAGE}        - creates the base docker image that host Jenkins'
>	@echo '  ${DEPLOY}       - creates a container from the project image'
>	@echo '  ${DISMANTLE}    - removes a deployed container and the supporting'
>	@echo '                 environment setup'
>	@echo '  ${LINT}         - performs linting on the yaml configuration files'
>	@echo '  ${PUBLISH}      - publish docker image to the project image repository'
>	@echo '  ${TEST}         - runs test suite for the project'
>	@echo '  ${CLEAN}        - removes files generated from the configs target'
>	@echo 'Common make configurations (e.g. make [config]=1 [targets]):'
>	@echo '  ANSIBLE_JBC_LOG_SECRETS      - toggle logging secrets from Ansible when deploying a'
>	@echo '                                 project image (e.g. false/true, or 0/1)'
>	@echo '  CONTINUOUS_INTEGRATION       - toggle to possibly differentiate target behavior'
>	@echo '                                 during ci (e.g. false/true, or 0/1)'

.PHONY: ${SETUP}
${SETUP}: ${DOCKER_ANSIBLE_INVENTORY} ${PYENV_POETRY_SETUP}
>	${ANSIBLE_GALAXY} collection install --requirements-file ./requirements.yml

.PHONY: ${CONFIGS}
${CONFIGS}:
>	${JCASCUTIL} setup
>	${JCASCUTIL} addjobs --transform-rffw --merge-casc "${CHILD_CASC_FILE}" > "${TEMP_CASC_FILE}"
>	${JCASCUTIL} addagent-placeholder --numagents 1 --casc-path "${TEMP_CASC_FILE}" > "${CASC_FILE}"
>	rm --force "${TEMP_CASC_FILE}"

.PHONY: ${IMAGE}
${IMAGE}: ${DOCKER_IMAGE}

.PHONY: ${DEPLOY}
${DEPLOY}: ${DOCKER_TEST_DEPLOY}

.PHONY: ${DISMANTLE}
${DISMANTLE}: ${DOCKER_TEST_DEPLOY_DISMANTLE}

.PHONY: ${LINT}
${LINT}: ${ANSIBLE_LINT} ${YAMLLINT}

.PHONY: ${PUBLISH}
${PUBLISH}: ${DOCKER_PUBLISH}

.PHONY: ${TEST}
${TEST}:
>	${PYTHON} -m unittest --verbose

.PHONY: ${CLEAN}
${CLEAN}: ${DOCKER_IMAGE_CLEAN}
>	rm --force "${CASC_FILE}"
>	${JCASCUTIL} setup --clean
