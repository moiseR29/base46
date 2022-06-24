local merge_tb = require("base46").merge_tb
local ui = require("base46.default_config").ui

local highlights = {}

-- push hl_dir file names to table
local hl_files = vim.fn.stdpath "data" .. "/plugged/base46/lua/base46/integrations"

for _, file in ipairs(vim.fn.readdir(hl_files)) do
  local integration = require("base46.integrations." .. vim.fn.fnamemodify(file, ":r"))
  highlights = merge_tb(highlights, integration)
end

-- polish theme specific highlights
local polish_hl = require("base46").get_theme_tb "polish_hl"

if polish_hl then
  highlights = merge_tb(highlights, polish_hl)
end

-- override user highlights if there are any
local user_highlights = ui.hl_override
local colors = require("base46").get_theme_tb "base_30"

-- fg = "white" set by user becomes fg = colors["white"]
-- so no need for the user to import colors

for group, _ in pairs(user_highlights) do
  for key, val in pairs(user_highlights[group]) do
    if key == "fg" or key == "bg" then
      if val:sub(1, 1) == "#" or val == "none" or val == "NONE" then
        user_highlights[group][key] = val
      else
        user_highlights[group][key] = colors[val]
      end
    end
  end
end

highlights = merge_tb(highlights, user_highlights)

if vim.g.transparency then
  highlights = merge_tb(highlights, require "base46.glassy")
end

return highlights
