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

local yaml = require("lyaml")

---@module "ondemand.base"
--- Base module for configuration managers; they update YAML files so that you don't have to.
local base = {}

---@class Base
---@field protected file string "Configuration file location."
---@field private fh file* "File handler for configuration file."
local Base = {}

--- Open yaml configuration file.
---@param mode string "I/O mode to open file in. Accepts the same options as `io.open(...)`"
function Base:open(mode)
  local fh = io.open(self.file, mode)
  assert(fh, string.format("Failed to to open file %s in mode %s", self.file, mode))
  self.fh = fh
end

--- Close yaml configuration file.
function Base:close()
  self.fh:close()
end

--- Load yaml (deserialize) yaml configuration file.
---@return table "Contents of yaml configuration file."
function Base:load()
  self:open("r")
  local ctx = self.fh:read("*a")
  self:close()

  return yaml.load(ctx)
end

--- Dump configuration data into yaml configuration file.
---@param t table "Configuration data to dump into yaml file."
function Base:dump(t)
  self:open("w+")
  self.fh:write(yaml.dump(t))
  self:close()
end

--- Update configuration file.
---@param t table "New configuration data retrieved from snap subsystem."
function Base:update(t)
  local config = self:load()
  -- Replace "-" with "_" in top-level keys.
  for k, v in pairs(t) do
    if k:find("-") then
      k = k:gsub("-", "_")
    end
    config[k] = v
  end
  self:dump({ config })
end

---@param object table Properties that must be accessible to base methods.
function base.new(object)
  local self = object
  setmetatable(self, { __index = Base })
  return self
end

return base
