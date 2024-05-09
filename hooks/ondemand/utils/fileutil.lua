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

--- Utilities for working with files inside the `ondemand` snap.
---@module "ondemand.fileutil"
local fileutil = {}

--- Determine if given name is a directoy.
---@param fn string Name to check.
---@return boolean `true` if given name is a directory; `false` otherwise.
function fileutil.is_dir(fn)
  local info = posix.stat(fn)
  return info ~= nil and info.type == "directory"
end

--- Determine if given name is a file.
---@param fn string Name to check.
---@return boolean `true` if given name is a file; `false` otherwise.
function fileutil.is_file(fn)
  local info = posix.stat(fn)
  return info ~= nil and info.type == "regular"
end

--- Determine if a directory on file exists
---@param fn string Directory/file to check for existence of.
---@return boolean `true` if the directory/file exists; `false` otherwise. 
function fileutil.exists(fn)
  return posix.stat(fn) ~= nil
end

--- Copy a file or directory from one location to another.
---@param src string File or directory to copy to new location.
---@param target string Target location for copied file or directory.
function fileutil.copy(src, target)
  if fileutil.is_file(src) then
    os.execute(string.format("cp %s %s", src, target))
  elseif fileutil.is_dir(src) then
    os.execute(string.format("cp -R %s/. %s", src, target))
  else
    error(string.format("%s: No such file or directory", src))
  end
end

--- Create a directory tree based on a given path.
---@param target string Directory tree to create.
function fileutil.mkdirs(target)
  local r = ""
  for dir in string.gmatch(target, "[^/]+") do
    r = r .. string.format("/%s", dir)
    if not fileutil.exists(r) then
      posix.mkdir(r)
    end
  end
end

return fileutil
