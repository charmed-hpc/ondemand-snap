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

"""Models for managing lifecycle operations inside the Open OnDemand snap."""

import json
import logging
from abc import ABC, abstractmethod
from typing import Any, Dict, List

from ondemandutils.editors import nginx_stage, ood_portal
from ondemandutils.models import NginxStageConfig, OODPortalConfig
from snaphelpers import Snap


def _prefilter(config: Dict[str, Any]):
    """Filter dictionary keys with bars `-` and convert them to underscores `_`.

    Args:
        config: Dictionary to filter bar characters out of configuration keys.
    """
    filtered = {}
    for k, v in config.items():
        if "-" not in k:
            continue

        k = k.replace("-", "_")
        if isinstance(v, dict):
            filtered[k] = _prefilter(v)
        elif isinstance(v, list):
            holder = []
            for i in v:
                if isinstance(i, dict):
                    holder.append(_prefilter(i))
                else:
                    holder.append(i)

            filtered[k] = holder
        else:
            filtered[k] = v

    return filtered


class _BaseModel(ABC):
    """Abstract base class for lifecycle management models."""

    def __init__(self, snap: Snap) -> None:
        self._snap = snap

    def _needs_restart(self, services: List[str]) -> None:
        """Determine if service(s) need to be restarted to apply latest configuration.

        Args:
            services: List of services to check status of. If the service is active,
                log that the service needs to be restarted.
        """
        for service in services:
            if self._snap.services.list()[service].active:
                logging.info(
                    "Service `%s` must be restarted to apply latest configuration changes.",
                    service,
                )

    @abstractmethod
    def update_config(self, config: Dict[str, str]) -> None:  # pragma: no cover
        """Update configuration specific to the service.

        Every model must have this method as it will be used
        to process configuration retrieved via `snapctl`. This
        method makes it easier to do unit tests on the hooks
        since each method can be tested individually.
        """
        raise NotImplementedError


class OODPortal(_BaseModel):
    """Manage lifecycle operations for the Open OnDemand portal."""

    def __init__(self, *args) -> None:
        super().__init__(*args)
        self.config_file = self._snap.paths.common / "etc" / "ood" / "config" / "ood_portal.yaml"

    def generate_config(self) -> None:
        """Generate a default `ood_portal.yml` configuration file.

        This default configuration is used for the Open OnDemand portal.
        """
        config = OODPortalConfig.from_dict(
            {
                "listen_addr_port": None,
                "servername": None,
                "server_aliases": [],
                "proxy_server": None,
                "port": None,  # Default is 80 or 443 if SSL is enabled.
                "ssl": None,
                "disable_logs": False,
                "logroot": f"{self._snap.paths.common}/var/log/ood",
                "errorlog": "error.log",
                "accesslog": "access.log",
                "logformat": None,  # Default is 'Apache combined format'.
                "use_rewrites": True,
                "use_maintenance": True,
                "maintenance_ip_allowlist": [],
                "security_csp_frame_ancestors": "",
                "security_strict_transport": True,
                "lua_root": f"{self._snap.paths.snap}/mod_ood_proxy/lib",
                "lua_log_level": "info",
                "user_map_cmd": None,
                "user_map_match": "'.*'",
                "user_env": None,
                "map_fail_uri": None,
                "pun_stage_cmd": f"sudo {self._snap.paths.snap}/nginx_stage/sbin/nginx_stage",
                "auth": [],
                "custom_vhost_directives": [],
                "custom_location_directives": [],
                "root_uri": "/pun/sys/dashboard",
                "analytics": None,
                "public_uri": "/public",
                "public_root": f"{self._snap.paths.common}/var/www/ood/public",
                "logout_uri": "/logout",
                "logout_redirect": "/pun/sys/dashboard/pun",
                "host_regex": "'[^/]+'",
                "node_uri": None,
                "rnode_uri": None,
                "nginx_uri": "/nginx",
                "pun_uri": "/pun",
                "pun_socket_root": f"{self._snap.paths.common}/run/nginx",
                "pun_max_retries": 5,
                "pun_pre_hook_root_cmd": None,
                "pun_pre_hook_exports": None,
                "oidc_uri": None,
                "oidc_discover_uri": None,
                "oidc_discover_root": None,
                "register_uri": None,
                "register_root": None,
                "oidc_provider_metadata_url": None,
                "oidc_client_id": None,
                "oidc_client_secret": None,
                "oidc_remote_user_claim": "preferred_username",
                "oidc_scope": "openid profile email",
                "oidc_session_inactivity_timeout": 28800,
                "oidc_session_max_duration": 28800,
                "oidc_state_max_number_of_cookies": "10 true",
                "oidc_cookie_same_site": "On",
                "oidc_settings": {},
                "dex_uri": "/dex",
                "dex": None,  # Disable Dex configuration generation.
            }
        )
        ood_portal.dump(config, self.config_file)
        self.config_file.chmod(0o600)

    def update_config(self, config: Dict[str, Any], prefilter: bool = False) -> None:
        """Update configuration for the Open OnDemand portal interface."""
        if prefilter:
            config = _prefilter(config)

        new_config = OODPortalConfig.from_dict(config)
        old_config = ood_portal.load(self.config_file)
        new_config |= old_config
        if new_config == old_config:
            logging.debug("No change in portal configuration. Not updating.")
            return

        logging.info("Updating portal configuration file %s.", self.config_file)
        ood_portal.dump(new_config, self.config_file)
        self._needs_restart(["ondemand"])


class NginxStage(_BaseModel):
    """Manage lifecycle operations for `nginx_stage` utility."""

    def __init__(self, *args) -> None:
        super().__init__(*args)
        self.config_file = self._snap.paths.common / "etc" / "ood" / "config" / "nginx_stage.yaml"

    def generate_config(self) -> None:
        """Generate a default `nginx_stage.yml` configuration file.

        This default configuration is used for OnDemand's nginx_stage utility.
        """
        # TODO: Need to define further data models for nginx_stage.
        config = NginxStageConfig.from_dict({})
        nginx_stage.dump(config, self.config_file)
        self.config_file.chmod(0o644)

    def update_config(self, config: Dict[str, Any], prefilter: bool = False) -> None:
        """Update configuration for the `nginx_stage` utility."""
        if prefilter:
            config = _prefilter(config)

        new_config = NginxStageConfig.from_dict(config)
        old_config = nginx_stage.load(self.config_file)
        new_config |= old_config
        if new_config == old_config:
            logging.debug("No change in `nginx_stage` configuration. Not updating.")
            return

        logging.info("Updating `nginx_stage` configuration file %s.", self.config_file)
        nginx_stage.dump(new_config, self.config_file)


class Raw(_BaseModel):
    """Manage snap configuration using raw JSON objects.

    JSON object must map to a pre-existing data model inside the snap.
    An `AttributeError` will be raised if the JSON object contains
    any bad configuration values; a lint is performed on the passed configuration
    before any configuration inside the snap is updated.
    """

    def __init__(self, *args) -> None:
        super().__init__(*args)
        self._ood_portal = OODPortal(*args)
        self._nginx_stage = NginxStage(*args)

    def update_config(self, config: Dict[str, str]) -> None:
        """Update snap configuration using a JSON object."""
        if "portal" in config:
            logging.info(config["portal"])
            logging.info(type(config["portal"]))
            # TODO: Data is read in as a dict. No JSON parsing required.
            #   Update tomorrow to ingest configuration as dict without
            #   the JSON parsing.
            portal_config = json.loads(config["portal"])
            self._ood_portal.update_config(portal_config)

        if "nginx-stage" in config:
            nginx_stage_config = json.loads(config["nginx-stage"])
            self._nginx_stage.update_config(nginx_stage_config)
