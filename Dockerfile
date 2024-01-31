FROM jenkins/jenkins:jdk11@sha256:36fa8aa2d88c1c85bd3e8c21d7370ddfe32a103bdd06ddf8ab8d31006c53d2f3

ARG BRANCH
ARG COMMIT
LABEL tech.cavcrosby.jenkins.homelab.branch="${BRANCH}"
LABEL tech.cavcrosby.jenkins.homelab.commit="${COMMIT}"
LABEL tech.cavcrosby.jenkins.homelab.vcs-repo="https://github.com/cavcrosby/jenkins-homelab"

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
