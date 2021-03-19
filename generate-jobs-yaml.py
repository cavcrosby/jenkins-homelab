#!/usr/bin/env python3
# Standard Library Imports
import subprocess
import shutil
import sys
import os
import pathlib

# Third Party Imports
import ruamel.yaml
import toml
from ruamel.yaml.scalarstring import FoldedScalarString as folded

# Local Application Imports


PROGRAM_NAME = os.path.basename(sys.path[0])
PROGRAM_ROOT = os.getcwd()
JOBS_YAML_FILEPATH = f"{PROGRAM_ROOT}/jobs.yaml"
JOB_DSL_ROOT_KEY_YAML = "jobs"
JOB_DSL_SCRIPT_KEY_YAML = "scripts"
JOB_DSL_FILENAME_REGEX = ".*job-dsl.*"
GIT_REPOS_FILENAME = "jobs.toml"
GIT_REPOS = toml.load(GIT_REPOS_FILENAME)["git"]["repo_urls"]
OTHER_PROGRAMS_NEEDED = ["git", "find"]


def have_other_programs():

    for util in OTHER_PROGRAMS_NEEDED:
        if shutil.which(util) is None:
            print(f"{PROGRAM_NAME}: {util} cannot be found on the PATH!")
            return False

    return True


def find_job_dsl_file():

    completed_process = subprocess.run(
        [
            "find",
            ".",
            "-regextype",
            "sed",
            "-maxdepth",
            "1",
            "-regex",
            JOB_DSL_FILENAME_REGEX,
        ],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        encoding="utf-8",
    )
    # everything but the last index, as it is just ''
    # NOTE: while the func name assumes one file will be returned
    # its possible more than one can be returned
    job_dsl_files = completed_process.stdout.split("\n")[:-1]
    return job_dsl_files


def meets_job_dsl_filereqs(repo_name, job_dsl_files):

    num_of_job_dsls = len(job_dsl_files)
    if num_of_job_dsls == 0:
        print(
            f"{PROGRAM_NAME}: {repo_name} does not have a job-dsl file, skip"
        )
        return False
    elif num_of_job_dsls > 1:
        # there should be no ambiguity in what job-dsl script to run
        # NOTE: this is open to change
        print(
            f"{PROGRAM_NAME}: {repo_name} has more than one job-dsl file, skip!"
        )
        return False
    else:
        return True


def main():

    if not have_other_programs():
        sys.exit(1)
    for repo_url in GIT_REPOS:
        repo_name = os.path.basename(repo_url)
        subprocess.run(["git", "clone", "--quiet", repo_url, repo_name])
        os.chdir(repo_name)
        job_dsl_filenames = find_job_dsl_file()
        if not meets_job_dsl_filereqs(repo_name, job_dsl_filenames):
            os.chdir("..")
            shutil.rmtree(repo_name)
            continue
        job_dsl_filename = job_dsl_filenames[0]
        # read in the job_dsl file, fc == filecontents
        with open(job_dsl_filename, "r") as job_dsl_fh:
            job_dsl_fc = job_dsl_fh.read()
        yaml = ruamel.yaml.YAML()
        if not pathlib.Path(JOBS_YAML_FILEPATH).exists():
            open(JOBS_YAML_FILEPATH, "w").close()
        with open(JOBS_YAML_FILEPATH, "r") as yaml_f:
            data = yaml.load(yaml_f)
        with open(JOBS_YAML_FILEPATH, "w") as yaml_f:
            # NOTE: inspired from:
            # https://stackoverflow.com/questions/35433838/how-to-dump-a-folded-scalar-to-yaml-in-python-using-ruamel
            # fsc == filecontents-str
            job_dsl_fsc = folded(job_dsl_fc)
            # NOTE2: this handles the situation for multiple job-dsls:
            # create the 'JOB_DSL_SCRIPT_KEY_YAML: job_dsl_fsc' then
            # either merge into JOB_DSL_ROOT_KEY_YAML
            # or create the JOB_DSL_ROOT_KEY_YAML entry and append to it
            if data:
                data[JOB_DSL_ROOT_KEY_YAML].append(
                    dict([(JOB_DSL_SCRIPT_KEY_YAML, job_dsl_fsc)])
                )
            else:
                data = dict([(JOB_DSL_SCRIPT_KEY_YAML, job_dsl_fsc)])
                data = dict([(JOB_DSL_ROOT_KEY_YAML, [data])])
            yaml.dump(data, yaml_f)
        os.chdir("..")
        shutil.rmtree(repo_name)


if __name__ == "__main__":
    main()
