#!/usr/bin/env python3
"""
Install the gh CLI from GitHub pre-compiled releases.
"""

import os
import platform
import re
import sys
import tarfile
import tempfile
from io import BytesIO
from subprocess import check_call

import requests


PLATFORM_MAP = {
    "x86_64": "amd64"
}


def get_latest_version() -> str:
    r = requests.get(
        "https://github.com/cli/cli/releases/latest", allow_redirects=False
    )

    r.raise_for_status()

    assert r.status_code == 302

    location = r.headers["location"]

    assert location.startswith("https://github.com/cli/cli/releases/tag/")

    parts = location.split("/")
    version = parts[-1]

    m = re.search(r"^v[\d\.]+", version)
    if not m:
        raise ValueError(f"Version {version!r} doesn't match expected regex")

    return version


def get_cpu_arch() -> str:
    mach = platform.machine()
    return PLATFORM_MAP[mach]


def download_release(version: str, arch: str | None = None) -> bytes:
    if not arch:
        arch = get_cpu_arch()

    assert version.startswith("v")
    version_no_v = version[1:]
    baseurl = "https://github.com/cli/cli/releases/download/"
    url = baseurl + f"{version}/gh_{version_no_v}_linux_{arch}.tar.gz"

    r = requests.get(url)
    r.raise_for_status()

    return r.content


def download_and_install_latest_gh():
    version = get_latest_version()

    print("Downloading and installing gh CLI version " + version)

    bundle = download_release(version=version)

    print("Downloaded .tar.gz installer")

    with tempfile.TemporaryDirectory() as tempd:
        tf = tarfile.open(fileobj=BytesIO(bundle), mode="r|gz")
        tf.extractall(tempd, filter="data")

        extracted = os.listdir(tempd)
        print(f"Extracted tree {extracted!r}")
        assert len(extracted) == 1

        root = extracted[0]
        assert root.startswith("gh_")

        os.chdir(os.path.join(tempd, root))

        cmd = ["sudo", "cp", "-v", "bin/gh", "/usr/local/bin/"]
        run_print(cmd)

        manfiles = os.listdir("share/man/man1/")
        full_manfiles = ["share/man/man1/" + f for f in manfiles]

        man_dest = "/usr/local/share/man/man1/"
        if not os.path.exists(man_dest):
            run_print(["sudo", "mkdir", "-v", man_dest])

        cmd = ["sudo", "cp", "-v", "-t", man_dest] + full_manfiles
        run_print(cmd)


def run_print(cmd: list[str]):
    sys.stderr.write("+ " + " ".join(cmd) + "\n")
    return check_call(cmd)


if __name__ == "__main__":
    download_and_install_latest_gh()
