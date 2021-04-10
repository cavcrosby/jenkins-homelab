FROM reap2sow1/jenkins-base:v1.0.9

ARG BRANCH
ARG COMMIT
LABEL tech.conneracrosby.jenkins.torkel.branch="${BRANCH}"
LABEL tech.conneracrosby.jenkins.torkel.commit="${COMMIT}"
LABEL tech.conneracrosby.jenkins.torkel.vcs-repo="https://github.com/reap2sow1/jenkins-docker-torkel"

# WD ==> WORKING_DIR...
ENV WD "/jenkins-torkel"
ENV REPOS_TO_TRANSFER_DIR_NAME "projects"
ENV LOCAL_CASC_JENKINS_CONFIG_FILENAME "casc.yaml"
WORKDIR "$WD"

USER root
# allows operations to occur in WORKDIR as normal jenkins user
RUN chown jenkins:jenkins "$WD"

USER jenkins
# COPY instruction only copies the contents of <src> into <dst>
# also per the Docker reference:
# "If <dest> doesn’t exist, it is created along with all missing directories in its path."
COPY "$REPOS_TO_TRANSFER_DIR_NAME" "$WD/$REPOS_TO_TRANSFER_DIR_NAME"
COPY "$LOCAL_CASC_JENKINS_CONFIG_FILENAME" "$CASC_JENKINS_CONFIG"
