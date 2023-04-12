FROM jenkins/jenkins:jdk11@sha256:5bda788cb0723b83592903f17f3d67dbf2522084c8501956bfe7c6c2a9b79cad

ARG BRANCH
ARG COMMIT
LABEL tech.cavcrosby.jenkins.torkel.branch="${BRANCH}"
LABEL tech.cavcrosby.jenkins.torkel.commit="${COMMIT}"
LABEL tech.cavcrosby.jenkins.torkel.vcs-repo="https://github.com/cavcrosby/jenkins-torkel"

ENV CASC_JENKINS_CONFIG_FILE "casc.yaml"
ENV PLUGINS_FILE "plugins.txt"
ENV JENKINS_UC_DOWNLOAD_URL "https://ftp-chi.osuosl.org/pub/jenkins/plugins"
ENV JAVA_OPTS "-Djenkins.install.runSetupWizard=false -Dmail.smtp.starttls.enable=true"

# CASC_JENKINS_CONFIG is already picked up by the plugin, do not change to
# 'CASC_JENKINS_CONFIG_PATH'. Also, JENKINS_HOME is already defined by parent
# image.
ENV CASC_JENKINS_CONFIG "/usr/share/jenkins/ref/${CASC_JENKINS_CONFIG_FILE}"
ENV PLUGINS_FILE_PATH "/usr/share/jenkins/ref/${PLUGINS_FILE}"

COPY "${CASC_JENKINS_CONFIG_FILE}" "${CASC_JENKINS_CONFIG}"
COPY "${PLUGINS_FILE}" "${PLUGINS_FILE_PATH}"
RUN jenkins-plugin-cli --plugin-file "${PLUGINS_FILE_PATH}"
