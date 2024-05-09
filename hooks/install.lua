#!/usr/bin/env lua5.3
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

local posix = require("posix")
local snap = require("snap")

local logger = require("ondemand.logging")
local fileutil = require("ondemand.fileutil")
local portal = require("ondemand.portal")
local nginx_stage = require("ondemand.nginx-stage")

--- Stage `ondemand` snap resources so that it is ready to go for the first start.
local function stage()
  -- Provision required directories for `ondemand` snap.
  local etc = snap.paths.common .. "/etc"
  local run = snap.paths.common .. "/run"
  local var_lib = snap.paths.common .. "/var/lib"
  local var_log = snap.paths.common .. "/var/log"
  local var_www = snap.paths.common .. "/var/www"
  local dirs = {
    etc .. "/httpd/conf.d",
    etc .. "/ondemand/clusters.d",
    etc .. "/ondemand/ondemand.d",
    run .. "/nginx",
    var_lib .. "/nginx/config/puns",
    var_lib .. "/nginx/config/app/sys",
    var_lib .. "/nginx/config/app/usr",
    var_lib .. "/nginx/config/app/dev",
    var_log .. "/httpd",
    var_log .. "/ondemand",
    var_www .. "/ondemand/public/maintenance",
    var_www .. "/ondemand/discover",
    var_www .. "/ondemand/register",
    var_www .. "/ondemand/apps/sys",
    var_www .. "/ondemand/apps/usr",
    var_www .. "/ondemand/apps/dev",
  }
  for _, dir in ipairs(dirs) do
    logger:debug(string.format("Creating directory %s.", dir))
    fileutil.mkdirs(dir)
  end

  -- Copy required files (that must be mutable!) from $SNAP to
  -- target locations under $SNAP_COMMON.
  local templates = snap.paths.snap .. "/templates"

  local public = snap.paths.common .. "/var/www/ondemand/public"
  local public_targets = {
    [templates .. "/maintenance.html"] = public .. "/maintenance/index.html",
    [templates .. "/need_auth.html"] = public .. "/need_auth.html",
    [snap.paths.snap .. "/ondemand/apps"] = snap.paths.common .. "/var/www/ondemand/apps/sys"
  }
  for src, target in pairs(public_targets) do
    logger:debug(string.format("Copying public resource %s to %s.", src, target))
    fileutil.copy(src, target)
    posix.chmod(target, "rw-r--r--")
  end

  local apps = snap.paths.common .. "/var/www/ondemand/apps/sys"
  logger:debug(string.format("Copying system applications to %s.", apps))
  fileutil.copy(snap.paths.snap .. "/ondemand/apps", apps)
  posix.chmod(apps, "rwxr-xr-x")
end

--- `install` hook for the ondemand snap.
local function install()
  logger:info("Executing `install` hook.")
  stage()

  logger:info("Generating default `ood-portal.yaml` configuration file.")
  portal:default()

  logger:info("Generating default `nginx-stage.yaml` configuration file.")
  nginx_stage:default()
end

install()
