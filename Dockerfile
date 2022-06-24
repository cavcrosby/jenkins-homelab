FROM cavcrosby/jenkins-base:v2.7.0

ARG BRANCH
ARG COMMIT
LABEL tech.cavcrosby.jenkins.torkel.branch="${BRANCH}"
LABEL tech.cavcrosby.jenkins.torkel.commit="${COMMIT}"
LABEL tech.cavcrosby.jenkins.torkel.vcs-repo="https://github.com/cavcrosby/jenkins-docker-torkel"

ENV WORKING_DIR "/jenkins-torkel"
ENV REPOS_TO_TRANSFER_DIR "projects"
ENV LOCAL_CASC_JENKINS_CONFIG "casc.yaml"
WORKDIR "${WORKING_DIR}"

USER root
# allows operations to occur in WORKDIR as normal jenkins user
RUN chown jenkins:jenkins "${WORKING_DIR}"

USER jenkins
# COPY instruction only copies the contents of SRC into DEST. Also if DEST
# doesn’t exist, it is created along with all missing directories in its path.
# For reference: https://docs.docker.com/engine/reference/builder/#copy
COPY "${REPOS_TO_TRANSFER_DIR}" "${WORKING_DIR}/${REPOS_TO_TRANSFER_DIR}"
COPY "${LOCAL_CASC_JENKINS_CONFIG}" "${CASC_JENKINS_CONFIG}"
