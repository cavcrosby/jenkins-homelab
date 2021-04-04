# for multi-stage builder reference: 
# https://docs.docker.com/develop/develop-images/multistage-build/
# WD ==> WORKING_DIR...no there is not a way to persist env vars across multi-stage builds:
# https://stackoverflow.com/questions/53541362/persist-env-in-multi-stage-docker-build
### setting up WD and needed 'resources' - builder_1
FROM reap2sow1/jenkins-base:v1.0.8 AS builder_1

ENV WD "/jenkins-torkel"
ENV JCASC_UTIL_SCRIPT_NAME "jcasc.py"
ENV REPOS_TO_TRANSFER_DIR_NAME "projects"
WORKDIR "$WD"

USER root
# allows operations to occur in WORKDIR as normal
# jenkins user
RUN chown jenkins:jenkins "$WD"

USER jenkins
COPY jobs.toml "$WD"
COPY "$JCASC_UTIL_SCRIPT_NAME" "$WD"
# COPY instruction only copies the contents of <src> into <dst>
# per the Docker reference:
# "If <dest> doesn’t exist, it is created along with all missing directories in its path."
COPY "$REPOS_TO_TRANSFER_DIR_NAME" "$WD/$REPOS_TO_TRANSFER_DIR_NAME"

# looks for the base casc.yaml (assuming its called this) in env
# and add jobs based on repos pulled when running in docker context 
# before hand
RUN ./"${JCASC_UTIL_SCRIPT_NAME}" addjobs --transform-rffw > "$CASC_JENKINS_CONFIG_FILENAME"

###

### setting up WD and needed 'resources' - builder_2
FROM reap2sow1/jenkins-base:v1.0.8 AS builder_2

ENV WD "/jenkins-torkel"
ENV JCASC_UTIL_SCRIPT_NAME "jcasc.py"
ENV REPOS_TO_TRANSFER_DIR_NAME "projects"
WORKDIR "$WD"

USER root
# allows operations to occur in WORKDIR as normal
# jenkins user
RUN chown jenkins:jenkins "$WD"

USER jenkins
COPY jobs.toml "$WD"
COPY "$JCASC_UTIL_SCRIPT_NAME" "$WD"
# COPY instruction only copies the contents of <src> into <dst>
# per the Docker reference:
# "If <dest> doesn’t exist, it is created along with all missing directories in its path."
COPY "$REPOS_TO_TRANSFER_DIR_NAME" "$WD/$REPOS_TO_TRANSFER_DIR_NAME"

COPY --from=builder_1 "$WD/$CASC_JENKINS_CONFIG_FILENAME" "$JENKINS_HOME"
RUN ./"${JCASC_UTIL_SCRIPT_NAME}" addnode-placeholder --numnodes 1 > "$CASC_JENKINS_CONFIG_FILENAME"

###

### 
FROM reap2sow1/jenkins-base:v1.0.8

ARG BRANCH
ARG COMMIT
LABEL tech.conneracrosby.jenkins.torkel.branch="${BRANCH}"
LABEL tech.conneracrosby.jenkins.torkel.commit="${COMMIT}"
LABEL tech.conneracrosby.jenkins.torkel.vcs-repo="https://github.com/reap2sow1/jenkins-docker-torkel"

ENV WD "/jenkins-torkel"
WORKDIR "$WD"
COPY --from=builder_2 "$WD/$CASC_JENKINS_CONFIG_FILENAME" "$JENKINS_HOME"
COPY "$REPOS_TO_TRANSFER_DIR_NAME" "$WD/$REPOS_TO_TRANSFER_DIR_NAME"
