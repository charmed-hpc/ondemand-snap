# Copyright 2024 Canonical Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Hooks for the Ondemand snap."""

import logging
from pathlib import Path

from snaphelpers import Snap

from .log import setup_logging


def _setup_dirs(snap: Snap) -> None:
    """Create directories required by Ondemand, Nginx, and Passenger.

    Args:
        snap: The Snap instance.
    """
    logging.info("Provisioning required directories for Ondemand, Nginx, and Passenger.")
    run = Path(snap.paths.common) / "run"
    etc = Path(snap.paths.common) / "etc"
    var = Path(snap.paths.common) / "var"
    for directory in [
        # etc - configuration files.
        etc / "apache2" / "conf.d",
        etc / "ood" / "config" / "clusters.d",
        etc / "ood" / "config" / "ondemand.d",
        # run - runtime variable data.
        run,
        # var/lib - variable state information.
        var / "lib" / "nginx" / "config" / "puns",
        var / "lib" / "nginx" / "config" / "app" / "sys",
        var / "lib" / "nginx" / "config" / "app" / "usr",
        var / "lib" / "nginx" / "config" / "app" / "dev",
        # var/log - variable log data.
        var / "log" / "apache",
        # var/www - variable web data.
        var / "www" / "ood" / "public" / "maintenance",
        var / "www" / "ood" / "discover",
        var / "www" / "ood" / "register",
        var / "www" / "ood" / "apps" / "sys",
        var / "www" / "ood" / "apps" / "usr",
        var / "www" / "ood" / "apps" / "dev",
    ]:
        logging.debug("Generating directory %s.", directory)
        directory.mkdir(parents=True)


def install(snap: Snap) -> None:
    """Install hook for the Ondemand snap."""
    setup_logging(snap.paths.common / "hooks.log")

    logging.info("Executing snap `install` hook.")
    _setup_dirs(snap)
