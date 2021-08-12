# special makefile variables
.DEFAULT_GOAL := help
.RECIPEPREFIX := >

# recursive variables
SHELL = /usr/bin/sh
CASC_FILE = casc.yaml
CHILD_CASC_FILE = child-casc.yaml
TEMP_CASC_FILE = temp-casc.yaml

# targets
HELP = help
CONFIGS = configs
CLEAN = clean

# executables
JCASCUTIL = jcascutil
executables = \
	${JCASCUTIL}

# simply expanded variables

# certain executables should exist before running, inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach exec,${executables},$(if $(shell command -v ${exec}),pass,$(error "No ${exec} in PATH")))

.PHONY: ${HELP}
${HELP}:
	# inspired by the makefiles of the Linux kernel and Mercurial
>	@echo 'Available make targets:'
>	@echo '  ${CONFIGS}     - creates/pulls the needed material to perform a docker build.'
>	@echo '  ${CLEAN}       - removes files generated from the ${CONFIGS} target.'

.PHONY: ${CONFIGS}
${CONFIGS}:
>	${JCASCUTIL} setup
>	${JCASCUTIL} addjobs --transform-rffw --merge-casc "${CHILD_CASC_FILE}" > "${TEMP_CASC_FILE}"
>	${JCASCUTIL} addagent-placeholder --numagents 1 --casc-path "${TEMP_CASC_FILE}" > "${CASC_FILE}"
>	rm --force "${TEMP_CASC_FILE}"

.PHONY: ${CLEAN}
${CLEAN}:
>	rm --force "${CASC_FILE}"
>	${JCASCUTIL} setup --clean
