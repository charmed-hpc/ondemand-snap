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

local snap = require("snap")

local base = require("ondemand.base")
local logger = require("ondemand.utils.logging")

--- Configuration manager for `ondemand` portal (ood-portal.yaml).
---@class Portal : Base
local Portal = base.new {
  file = snap.paths.common .. "/etc/ondemand/ood-portal.yaml"
}

--- Generate default _ood-portal.yaml_ configuration file for `ondemand`.
function Portal:default()
  logger:info("Generating default `ood-portal.yaml` configuration file.")
  self:dump(
    { {
      logroot = snap.paths.common .. "/var/log/ondemand",
      lua_root = snap.paths.snap .. "/ondemand/mod_ood_proxy/lib",
      pun_stage_cmd = "sudo " .. snap.paths.snap .. "/ondemand/nginx_stage/sbin/nginx_stage",
      public_root = snap.paths.common .. "/var/www/ondemand/public",
      pun_socket_root = snap.paths.common .. "/run/nginx",
    } }
  )
end

return Portal
