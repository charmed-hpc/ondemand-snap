-- Copyright 2024 Canonical Ltd.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Wrapper for `nginx-stage` configuration. `nginx-stage` is a CLI
-- utility used by `ondemand` to manage per-user nginx processes.

local snap = require("snap")

local base = require("ondemand.base")
local logger = require("ondemand.utils.logging")

--- Configuration manager for `nginx-stage`.
---@class NginxStage : Base
local NginxStage = base.new {
  file = snap.paths.common .. "/etc/ondemand/nginx-stage.yaml"
}

--- Generate default _nginx-stage.yaml_ configuration file for `nginx_stage`.
function NginxStage:default()
  logger:info("Generating default `nginx-stage.yaml` configuration file.")
  self:dump(
    { {
      ondemand_version_path = snap.paths.snap .. "/ondemand/VERSION",
      pun_custom_env_declarations = { "PATH", "LD_LIBRARY_PATH", "MANPATH", "GEM_PATH", "RUBYLIB" },
      template_root = snap.paths.snap .. "/ondemand/nginx_stage/templates",
      nginx_bin = snap.paths.snap .. "/sbin/nginx.wrapper",
      nginx_signals = { "stop", "quit", "reopen", "reload" },
      mime_types_path = snap.paths.snap .. "/nginx/conf/mime.types",
      passenger_root = snap.paths.snap .. "/passenger",
      passenger_ruby = snap.paths.snap .. "/usr/bin/ruby",
      passenger_nodejs = snap.paths.snap .. "/bin/node",
      passenger_log_file = snap.paths.common .. "/var/log/nginx/%{user}/error.log",
      pun_config_path = snap.paths.common .. "/var/lib/nginx/config/puns/%{user}.conf",
      pun_tmp_root = snap.paths.common .. "/var/tmp/nginx/%{user}",
      pun_access_log_path = snap.paths.common .. "/var/log/nginx/%{user}/access.log",
      pun_error_log_path = snap.paths.common .. "/var/log/nginx/%{user}/error.log",
      pun_secret_key_base_path = snap.paths.common .. "/var/lib/nginx/config/puns/%{user}.secret_key_base.txt",
      pun_pid_path = snap.paths.common .. "/run/nginx/%{user}/passenger.pid",
      pun_socket_path = snap.paths.common .. "/run/nginx/%{user}/passenger.sock",
      app_config_path = {
        dev = snap.paths.common .. "/var/lib/nginx/config/dev/%{owner}/%{name}.conf",
        usr = snap.paths.common .. "/var/lib/nginx/config/usr/%{owner}/%{name}.conf",
        sys = snap.paths.common .. "/var/lib/nginx/config/sys/%{name}.conf",
      },
      app_root = {
        dev = snap.paths.common .. "/var/www/ondemand/apps/dev/%{owner}/gateway/%{name}",
        usr = snap.paths.common .. "/var/www/ondemand/apps/usr/%{owner}/gateway/%{name}",
        sys = snap.paths.common .. "/var/www/ondemand/apps/sys/%{name}",
      },
      disable_bundle_user_config = false -- option not recognized by Passeneger :/
    } }
  )
end

return NginxStage
