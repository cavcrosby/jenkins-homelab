"""Runs tests to verify the integrity of the Jenkins image."""
# Standard Library Imports
import os
import sys
import time
import unittest

# Third Party Imports
from api4jenkins import Jenkins
import docker

# Local Application Imports

# constants and other program configurations
_docker_client = docker.from_env()

_DOCKER_TEST_CONTAINER_NAME = f"{os.environ['CONTAINER_NAME']}-tests"
_DOCKER_TEST_IMAGE = (
    f"{os.environ['DOCKER_REPO']}:{os.environ['DOCKER_CONTEXT_TAG']}"
)
DOCKER_TESTS_NETWORK = "jc-tests"
JENKINS_ADMIN_ID = "cavcrosby"
JENKINS_ADMIN_PASSWORD = "Passw0rd!"
JENKINS_HTTP_PORT = "8080"
JENKINS_AGENT_PORT = "50000"


class TestJenkinsHealth(unittest.TestCase):
    """Check if Jenkins was able to initialize successfully."""

    def setUp(self):
        """Set up environment before running test method(s)."""
        self.docker_network = _docker_client.networks.create(
            DOCKER_TESTS_NETWORK
        )
        self.container = _docker_client.containers.run(
            detach=True,
            environment={
                "JENKINS_ADMIN_ID": JENKINS_ADMIN_ID,
                "JENKINS_ADMIN_PASSWORD": JENKINS_ADMIN_PASSWORD,
            },
            image=_DOCKER_TEST_IMAGE,
            network=DOCKER_TESTS_NETWORK,
            name=_DOCKER_TEST_CONTAINER_NAME,
            ports={
                f"{JENKINS_HTTP_PORT}/tcp": JENKINS_HTTP_PORT,
                f"{JENKINS_AGENT_PORT}/tcp": JENKINS_AGENT_PORT,
            },
            volumes=["jenkins_home:/var/jenkins_home"],
        )

    def tearDown(self):
        """Tear down environment after running test method(s)."""
        self.container.kill()
        self.container.remove()
        self.docker_network.remove()

    def test_jenkins_health(self):
        """Check if Jenkins was able to initialize successfully."""
        # give time for Jenkins to spin up
        time.sleep(30)

        self.container.reload()
        jenkins_instance = Jenkins(
            f"http://127.0.0.1:{JENKINS_HTTP_PORT}",
            auth=(JENKINS_ADMIN_ID, JENKINS_ADMIN_PASSWORD),
        )
        container_exitcode = self.container.attrs["State"]["ExitCode"]
        self.assertEqual(
            container_exitcode,
            0,
            f"Container exit code: {container_exitcode}",
        )
        self.assertTrue(jenkins_instance.exists(), jenkins_instance.api_json())


if __name__ == "__main__":
    unittest.main()
    sys.exit(0)
