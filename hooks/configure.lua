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

local snap = require("snap")

local portal = require("ondemand.portal")
local nginx_stage = require("ondemand.nginx-stage")
local logger = require("ondemand.utils.logging")

--- `configure` hook for the ondemand snap.
local function configure()
  logger:info("Executing `configure` hook.")
  local config = snap.config:get_options("portal", "nginx-stage")

  if config["portal"] then
    logger:info("Updating `ondemand` portal configuration.")
    portal:update(config["portal"])
  end

  if config["nginx-stage"] then
    logger:info("Updating `nginx-stage` configuration.")
    nginx_stage:update(config["nginx-stage"])
  end
end

configure()
