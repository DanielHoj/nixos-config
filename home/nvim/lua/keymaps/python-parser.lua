---@class utils.python_parser
local M = {}

---@param lines table|string Lines to process
---@return string Processed text with proper indentation
local function process_indentation(lines)
  -- Handle case when lines is a single string (one line selected)
  if type(lines) == "string" then
    return lines -- Return as-is, don't strip indentation
  end

  -- Find minimum indentation across all non-empty lines
  local min_indent = nil
  for _, line in ipairs(lines) do
    if not line:match("^%s*$") then -- Skip empty lines
      local indent = line:match("^%s*"):len()
      if min_indent == nil or indent < min_indent then
        min_indent = indent
      end
    end
  end

  -- If all lines are blank or no common indentation found
  if min_indent == nil then
    return table.concat(lines, "\n")
  end

  -- Remove exactly min_indent spaces from the beginning of each line
  local result = {}
  for i, line in ipairs(lines) do
    -- Only remove indentation from non-empty lines
    if line:match("^%s*$") then
      result[i] = line -- Keep empty lines as is
    else
      result[i] = line:sub(min_indent + 1)
    end
  end

  -- Ensure we're returning actual newlines, not string literals
  local processed_text = table.concat(result, "\n")
  return processed_text
end

---@return table|string Text from visual line selection
local function get_visual_line_text()
  local start_line = vim.fn.getpos("v")[2]
  local end_line = vim.fn.getpos(".")[2]
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  return vim.fn.getline(start_line, end_line)
end

---@return table Text from visual character selection
local function get_visual_char_text()
  vim.cmd('normal! "ay')
  local selected_text = vim.fn.getreg('a')
  return vim.split(selected_text, '\n', { plain = true })
end

---@return string Selected or current line text based on Vim mode
function M.get_text()
  local mode = vim.fn.mode()
  if mode == 'V' then     -- Visual line mode
    return process_indentation(get_visual_line_text())
  elseif mode == 'v' then -- Visual character mode
    return process_indentation(get_visual_char_text())
  elseif mode == 'n' then -- Normal mode
    return process_indentation(vim.fn.getline('.'))
  else
    return ''
  end
end

return M
