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

"""Hooks for the Open OnDemand snap."""

import logging
import shutil

from snaphelpers import Snap

from .log import setup_logging
from .models import NginxStage, OODPortal


def _setup_dirs(snap: Snap) -> None:
    """Create directories required by Ondemand, Nginx, and Passenger.

    Args:
        snap: The `Snap` instance.
    """
    logging.info("Provisioning required directories for Ondemand, Nginx, and Passenger.")
    run = snap.paths.common / "run"
    etc = snap.paths.common / "etc"
    var = snap.paths.common / "var"
    for directory in [
        # etc - configuration files.
        etc / "apache2" / "conf.d",
        etc / "ood" / "config" / "clusters.d",
        etc / "ood" / "config" / "ondemand.d",
        # run - runtime variable data.
        run,
        run / "nginx",
        # var/lib - variable state information.
        var / "lib" / "nginx" / "config" / "puns",
        var / "lib" / "nginx" / "config" / "app" / "sys",
        var / "lib" / "nginx" / "config" / "app" / "usr",
        var / "lib" / "nginx" / "config" / "app" / "dev",
        # var/log - variable log data.
        var / "log" / "apache",
        var / "log" / "ood",
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


def _copy_resources(snap: Snap) -> None:
    """Copy resources from read-only loop device into mutable location.

    Args:
        snap: The `Snap` instance.
    """
    public_dir = snap.paths.common / "var" / "www" / "ood" / "public"

    logging.debug("Copying resource `maintenance.html` from mounted ondemand loop device.")
    maintenance = snap.paths.snap / "ood-portal-generator" / "share" / "maintenance.html"
    maintenance_target = public_dir / "maintenance" / "index.html"
    shutil.copy(maintenance, maintenance_target)
    maintenance_target.chmod(0o644)

    logging.debug("Copying resource `need_auth.html` from mounted ondemand loop device.")
    need_auth = snap.paths.snap / "ood-portal-generator" / "share" / "need_auth.html"
    need_auth_target = public_dir / "need_auth.html"
    shutil.copy(need_auth, need_auth_target)
    need_auth_target.chmod(0o644)


def install(snap: Snap) -> None:
    """Install hook for the Ondemand snap."""
    setup_logging(snap.paths.common / "hooks.log")
    ood_portal = OODPortal(snap)
    nginx_stage = NginxStage(snap)

    logging.info("Executing snap `install` hook.")
    _setup_dirs(snap)
    _copy_resources(snap)

    logging.info("Generating default `ood_portal.yml` configuration file.")
    ood_portal.generate_config()

    logging.info("Generating default `nginx_stage.yml` configuration file.")
    nginx_stage.generate_config()

