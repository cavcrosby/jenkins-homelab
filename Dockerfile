FROM reap2sow1/jenkins-base:v1.0.5

ARG BRANCH
ARG COMMIT
LABEL tech.conneracrosby.jenkins.torkel.branch=${BRANCH}
LABEL tech.conneracrosby.jenkins.torkel.commit=${COMMIT}
LABEL tech.conneracrosby.jenkins.torkel.vcs-repo="https://github.com/reap2sow1/jenkins-docker-torkel"

# WD ==> WORKING_DIR
ENV WD "/jenkins-torkel"
WORKDIR "$WD"

USER root
RUN chown jenkins "$WD"
USER jenkins
COPY jobs.toml "$WD"
RUN git clone --quiet "$JOB_YAML_GENERATOR_REPO_URL" "$(basename "$JOB_YAML_GENERATOR_REPO_URL")"
RUN cp "${JOB_YAML_GENERATOR_REPOFILE_PATH}" "$PWD"
# TODO(conner@conneracrosby.tech): the below is a work around, but python packages installed appear to be only in the RUN instruction's shell instance (and non-persistent on the filesystem!)
RUN pip3 install ruamel.yaml toml; ./$(basename "$JOB_YAML_GENERATOR_REPOFILE_PATH")
