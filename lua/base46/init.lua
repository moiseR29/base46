local M = {}
local g = vim.g
local u = require "utils"

local config = require "base46.default_config"

M.reload_theme = function(theme_name)
  if theme_name == nil or theme_name == "" then
    theme_name = "nightowl"
  end

  local default_teme = pcall(require, vim.fn.stdpath "data" .. "/plugged/base46/lua/base46/themes/" .. theme_name)

  if not default_teme then
    print("No such theme (" .. theme_name .. " )")
    return false
  end

  M.load_all_highlights()
  return theme_name
end

M.get_theme_tb = function(type)
  local default_path = "base46.themes." .. g.m_theme

  local present1, default_theme = pcall(require, default_path)

  if present1 then
    return default_theme[type]
  else
    error "No such theme bruh >_< "
  end
end

M.merge_tb = function(table1, table2)
  return u.merge(table1, table2)
end

M.clear_highlights = function(hl_group)
  local highlights_raw = vim.split(vim.api.nvim_exec("filter " .. hl_group .. " hi", true), "\n")
  local highlight_groups = {}

  for _, raw_hi in ipairs(highlights_raw) do
    table.insert(highlight_groups, string.match(raw_hi, hl_group .. "%a+"))
  end

  for _, highlight in ipairs(highlight_groups) do
    vim.cmd([[hi clear ]] .. highlight)
  end
end

M.load_all_highlights = function()
  vim.opt.bg = require("base46").get_theme_tb "type" -- dark/light

  local reload = require("plenary.reload").reload_module
  local clear_hl = require("base46").clear_highlights

  clear_hl "BufferLine"
  clear_hl "TS"

  reload "base46.integrations"
  reload "base46.chadlights"

  local hl_groups = require "base46.chadlights"

  for hl, col in pairs(hl_groups) do
    vim.api.nvim_set_hl(0, hl, col)
  end
end

M.turn_str_to_color = function(tb)
  local colors = M.get_theme_tb "base_30"

  for _, groups in pairs(tb) do
    for k, v in pairs(groups) do
      if k == "fg" or k == "bg" then
        if v:sub(1, 1) == "#" or v == "none" or v == "NONE" then
        else
          groups[k] = colors[v]
        end
      end
    end
  end

  return tb
end

M.extend_default_hl = function(highlights)
  local glassy = require "base46.glassy"
  local polish_hl = M.get_theme_tb "polish_hl"

  if polish_hl then
    -- polish themes
    for key, value in pairs(polish_hl) do
      if highlights[key] then
        highlights[key] = value
      end
    end
  end

  -- transparency
  if g.transparency then
    for key, value in pairs(glassy) do
      if highlights[key] then
        highlights[key] = M.merge_tb(highlights[key], value)
      end
    end
  end

  local overriden_hl = M.turn_str_to_color(config.ui.hl_override)

  for key, value in pairs(overriden_hl) do
    if highlights[key] then
      highlights[key] = M.merge_tb(highlights[key], value)
    end
  end
end

M.load_highlight = function(group)
  if type(group) == "string" then
    group = require("base46.integrations." .. group)
    M.extend_default_hl(group)
  end

  for hl, col in pairs(group) do
    vim.api.nvim_set_hl(0, hl, col)
  end
end

M.load_theme = function()
  -- set bg option
  local theme_type = M.get_theme_tb "type" -- dark/light
  vim.opt.bg = theme_type

  M.load_highlight "defaults"
  M.load_highlight "statusline"
  M.load_highlight(M.turn_str_to_color(config.ui.hl_add))
end

M.override_theme = function(default_theme, theme_name)
  local changed_themes = config.ui.changed_themes

  if changed_themes[theme_name] then
    return M.merge_tb(default_theme, changed_themes[theme_name])
  else
    return default_theme
  end
end

M.toggle_theme = function()
  local themes = config.ui.theme_toggle

  local theme1 = themes[1]
  local theme2 = themes[2]

  if g.m_theme == theme1 or g.m_theme == theme2 then
    if g.toggle_theme_icon == "   " then
      g.toggle_theme_icon = "   "
    else
      g.toggle_theme_icon = "   "
    end
  end

  if g.m_theme == theme1 then
    g.m_theme = theme2

    M.reload_theme()
  elseif g.m_theme == theme2 then
    g.m_theme = theme1

    M.reload_theme()
  else
    vim.notify "Please review the themes selected to swithcher"
  end
end

M.toggle_transparency = function()
  M.load_all_highlights()
end

return M
