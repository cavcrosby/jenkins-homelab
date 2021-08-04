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

# TODO(cavcrosby): using a shorter variable name w/comment < a tad longer variable name with no comment!
# NOTES: e ==> executable, certain executables should exist before
# running. Inspired from:
# https://stackoverflow.com/questions/5618615/check-if-a-program-exists-from-a-makefile#answer-25668869
_check_executables := $(foreach e,${executables},$(if $(shell command -v ${e}),pass,$(error "No ${e} in PATH")))

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
