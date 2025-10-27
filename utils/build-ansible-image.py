#!/bin/python3

import requests
import json
from urllib.parse import urljoin
from pprint import pprint
from sys import argv, stdout, stderr
from subprocess import run
from typing import List, Dict
import argparse
from time import strptime
from datetime import datetime, UTC

galaxyBaseUrl="https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/"
buildArgv=["buildah", "build",
        '--format', 'docker',
		"--tag", "aro-ansible:latest"
    ]
buildArgvEpilogue=["."]
forbidden_versions: Dict[str, List[str]] = dict()

def getPypiVersionDate(releases: dict) -> list:
    result = list()
    for k, v in releases.items():
        first_ts = None
        for item in v:
            if item.get("yanked", False):
                print(f"Skipping yanked version {k}")
                continue
            upload_time = datetime.fromisoformat(item.get("upload_time_iso_8601"))
            if first_ts is None or upload_time < first_ts:
                first_ts = upload_time
        if first_ts is not None:
            result.append((k, first_ts))
    return sorted(result, key=lambda x: x[1])

def getGalaxyVersion(namespace:str, name:str) -> str:
    package = f"{namespace}/{name}"
    url = f"https://galaxy.ansible.com/api/v3/plugin/ansible/content/published/collections/index/{package}/"
    forbidden = forbidden_versions.get(package, list())
    response = requests.get(url)
    data = json.loads(response.text)
    selected = data.get('highest_version', dict()).get('version')
    if selected in forbidden:
        print(f"{package}: latest {selected} is forbidden, picking the previous non-forbidden version")
        versions_url = urljoin(galaxyBaseUrl, data['versions_url'])
        response = requests.get(versions_url)
        data = json.loads(response.text)
        versions = [v['version'] for v in data['data'] if v['version'] not in forbidden]
        print(f"{namespace}/{name}: Selecting from {versions}")
        selected = versions[0]
    print(f"{package}: {selected}")
    return selected

def getPipVersion(package:str) -> str:
    forbidden = forbidden_versions.get(package, list())
    url = f"https://pypi.org/pypi/{package}/json"
    response = requests.get(url)
    data = json.loads(response.text)
    info = data.get('info', dict())
    if info.get('yanked', True):
        raise Exception(f"Package {package} is yanked")
    selected = info.get('version', '')
    if selected in forbidden:
        print(f"{package}: latest {selected} is forbidden, picking the previous non-forbidden version")
        releases = getPypiVersionDate(data.get("releases", dict()))
        versions = [x[0] for x in releases if x[0] not in forbidden]
        print(f"{package}: Selecting from {versions}")
        selected = versions[-1]
    print(f"{package}: {selected}")
    return selected

def loadForbiddenFile(forbidden_file: str) -> Dict[str, List[str]]:
    forbidden_versions: Dict[str, List[str]] = dict()
    with open(forbidden_file, "r") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split(" ", 2)
            package = parts[0].strip()
            version = parts[1].strip()
            if package not in forbidden_versions:
                forbidden_versions[package] = list()
            forbidden_versions[package].append(version)
    return forbidden_versions

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="build-ansible-image.py",
        description="Builds the ARO Ansible image",
        epilog="Example usage: build-ansible-image.py latest"
    )
    parser.add_argument("dockerfile", help="Path to the Dockerfile")
    parser.add_argument('--latest', action='store_true', help='Use "latest" to build with latest versions of everything')
    parser.add_argument('--build-arg', action='append', default=list(), help='Additional build arguments to pass to buildah')
    parser.add_argument('--tag', action='append', default=list(), help='Additional tags for the built image')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
    parser.add_argument('--dry-run', action='store_true', help='Do not actually run buildah, just print the command line')
    args = parser.parse_args()
    buildArgv.append("--file")
    buildArgv.append(args.dockerfile)
    for t in args.tag:
        buildArgv.append("--tag")
        buildArgv.append(t)
    if args.latest:
        print("Using latest versions of eveything")
        forbidden_versions = loadForbiddenFile(f"{args.dockerfile}.forbidden_versions")
        buildArgv.append("--build-arg")
        buildArgv.append("PIPX_VERSION=pipx") # + getPipVersion("pipx"))
        buildArgv.append("--build-arg")
        buildArgv.append("ANSIBLE_VERSION=ansible") # " + getPipVersion("ansible"))
        buildArgv.append("--build-arg")
        buildArgv.append("AZURE_CLI_VERSION=azure-cli") # " + getPipVersion("azure-cli"))
        buildArgv.append("--build-arg")
        buildArgv.append("ANSIBLE_LINT_VERSION=ansible-lint") # " + getPipVersion("ansible-lint"))

        buildArgv.append("--build-arg")
        buildArgv.append("ANSIBLE_AZCOLLECTION_VERSION=azure.azcollection") # + getGalaxyVersion("azure", "azcollection"))
    buildArgv += buildArgvEpilogue
    print(" ".join(buildArgv), flush=True)
    if not args.dry_run:
        run(buildArgv, stdout=stdout, stderr=stderr, check=True)
