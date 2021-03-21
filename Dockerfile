# for multi-stage builder reference: 
# https://docs.docker.com/develop/develop-images/multistage-build/
# WD ==> WORKING_DIR...no there is not a way to persist env vars across multi-stage builds:
# https://stackoverflow.com/questions/53541362/persist-env-in-multi-stage-docker-build
FROM reap2sow1/jenkins-base:v1.0.6 AS builder

ENV WD "/jenkins-torkel"
WORKDIR "$WD"

USER root
RUN chown jenkins:jenkins "$WD"

USER jenkins
COPY jobs.toml "$WD"
RUN git clone --quiet "$JOB_YAML_GENERATOR_REPO_URL" "$(basename "$JOB_YAML_GENERATOR_REPO_URL")"
RUN cp "${JOB_YAML_GENERATOR_REPOFILE_PATH}" "$WD"
RUN ./$(basename "$JOB_YAML_GENERATOR_REPOFILE_PATH")

FROM reap2sow1/jenkins-base:v1.0.6

ARG BRANCH
ARG COMMIT
LABEL tech.conneracrosby.jenkins.torkel.branch="${BRANCH}"
LABEL tech.conneracrosby.jenkins.torkel.commit="${COMMIT}"
LABEL tech.conneracrosby.jenkins.torkel.vcs-repo="https://github.com/reap2sow1/jenkins-docker-torkel"

ENV WD "/jenkins-torkel"
COPY --from=builder "$WD/$CASC_JENKINS_CONFIG_FILENAME" "$JENKINS_HOME"
