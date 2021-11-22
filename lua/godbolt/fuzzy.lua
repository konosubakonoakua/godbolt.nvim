local fun = vim.fn
local function get_compiler_list(cmd)
  local op = {}
  local jobid
  local function _1_(_, data, _0)
    return vim.list_extend(op, data)
  end
  jobid = fun.jobstart(cmd, {on_stdout = _1_})
  local t = fun.jobwait({jobid})
  local final = {}
  for k, v in pairs(op) do
    if (k ~= 1) then
      table.insert(final, v)
    else
    end
  end
  return final
end
local function transform(entry)
  return {value = (vim.split(entry, " "))[1], display = entry, ordinal = entry}
end
local function fzf(entries, begin, _end, options, exec)
  local function _3_(choice)
    local compiler = (vim.split(choice, " "))[1]
    do end (require("godbolt.assembly"))["pre-display"](begin, _end, compiler, options)
    if exec then
      return (require("godbolt.execute")).execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["fzf#run"]({source = entries, window = {width = 0.9, height = 0.6}, sink = _3_})
end
local function skim(entries, begin, _end, options, exec)
  local function _5_(choice)
    local compiler = (vim.split(choice, " "))[1]
    do end (require("godbolt.assembly"))["pre-display"](begin, _end, compiler, options)
    if exec then
      return (require("godbolt.execute")).execute(begin, _end, compiler, options)
    else
      return nil
    end
  end
  return fun["skim#run"]({source = entries, window = {width = 0.9, height = 0.6}, sink = _5_})
end
local function telescope(entries, begin, _end, options, exec)
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = (require("telescope.config")).values
  local actions = require("telescope.actions")
  local actions_state = require("telescope.actions.state")
  local function _7_(prompt_bufnr, map)
    local function _8_()
      actions.close(prompt_bufnr)
      local compiler = actions_state.get_selected_entry().value
      do end (require("godbolt.assembly"))["pre-display"](begin, _end, compiler, options)
      if exec then
        return (require("godbolt.execute")).execute(begin, _end, compiler, options)
      else
        return nil
      end
    end
    return (actions.select_default):replace(_8_)
  end
  return pickers.new({}, {prompt_title = "Choose compiler", finder = finders.new_table({results = entries, entry_maker = transform}), sorter = conf.generic_sorter(nil), attach_mappings = _7_}):find()
end
local function fuzzy(picker, ft, begin, _end, options, exec)
  local ft0
  do
    local _10_ = ft
    if (_10_ == "cpp") then
      ft0 = "c++"
    elseif (nil ~= _10_) then
      local x = _10_
      ft0 = x
    else
      ft0 = nil
    end
  end
  local cmd = string.format("curl https://godbolt.org/api/compilers/%s --limit-rate 1", ft0)
  local output = {}
  local jobid
  local function _12_(_, data, _0)
    return vim.list_extend(output, data)
  end
  local function _13_(_, _0, _1)
    local final
    do
      local tbl_14_auto = {}
      local i_15_auto = #tbl_14_auto
      for k, v in ipairs(output) do
        local val_16_auto
        if (k ~= 1) then
          val_16_auto = v
        else
          val_16_auto = nil
        end
        if (nil ~= val_16_auto) then
          i_15_auto = (i_15_auto + 1)
          do end (tbl_14_auto)[i_15_auto] = val_16_auto
        else
        end
      end
      final = tbl_14_auto
    end
    local _16_ = picker
    if (_16_ == "fzf") then
      return fzf(final, begin, _end, options, exec)
    elseif (_16_ == "telescope") then
      return telescope(final, begin, _end, options, exec)
    elseif (_16_ == "skim") then
      return skim(final, begin, _end, options, exec)
    else
      return nil
    end
  end
  jobid = fun.jobstart(cmd, {on_stdout = _12_, on_exit = _13_})
  return nil
end
return {fuzzy = fuzzy}
