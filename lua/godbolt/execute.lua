local fun = vim.fn
local api = vim.api
local wo_set = api.nvim_win_set_option
local exec_buf_map = _G.__godbolt_exec_buf_map
local function prepare_buf(lines, source_buf, reuse_3f)
  local time = os.date("*t")
  local hour = time.hour
  local min = time.min
  local sec = time.sec
  local buf
  if (reuse_3f and exec_buf_map[source_buf]) then
    buf = exec_buf_map[source_buf]
  else
    buf = api.nvim_create_buf(false, true)
  end
  exec_buf_map[source_buf] = buf
  api.nvim_buf_set_lines(buf, 0, 0, false, lines)
  api.nvim_buf_set_name(buf, string.format("%02d:%02d:%02d", hour, min, sec))
  return buf
end
local function display_output(response, source_buf, reuse_3f)
  local stderr
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for k, v in pairs(response.stderr) do
      local val_19_auto = v.text
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    stderr = tbl_17_auto
  end
  local stdout
  do
    local tbl_17_auto = {}
    local i_18_auto = #tbl_17_auto
    for k, v in pairs(response.stdout) do
      local val_19_auto = v.text
      if (nil ~= val_19_auto) then
        i_18_auto = (i_18_auto + 1)
        do end (tbl_17_auto)[i_18_auto] = val_19_auto
      else
      end
    end
    stdout = tbl_17_auto
  end
  local lines = {("exit code: " .. response.code)}
  table.insert(lines, "stdout:")
  vim.list_extend(lines, stdout)
  table.insert(lines, "stderr:")
  vim.list_extend(lines, stderr)
  local output_buf = prepare_buf(lines, source_buf, reuse_3f)
  local old_winid = fun.win_getid()
  vim.cmd("split")
  vim.cmd(("buffer " .. output_buf))
  wo_set(0, "number", false)
  wo_set(0, "relativenumber", false)
  wo_set(0, "spell", false)
  wo_set(0, "cursorline", false)
  return api.nvim_set_current_win(old_winid)
end
local function execute(begin, _end, compiler, options, reuse_3f)
  local lines = api.nvim_buf_get_lines(0, (begin - 1), _end, true)
  local text = fun.join(lines, "\n")
  local source_buf = fun.bufnr()
  do end (options)["compilerOptions"] = {executorRequest = true}
  local cmd = (require("godbolt.cmd"))["build-cmd"](compiler, text, options, "exec")
  local function _4_(_, _0, _1)
    local file = io.open("godbolt_response_exec.json", "r")
    local response = file:read("*all")
    file:close()
    os.remove("godbolt_request_exec.json")
    os.remove("godbolt_response_exec.json")
    return display_output(vim.json.decode(response), source_buf, reuse_3f)
  end
  return fun.jobstart(cmd, {on_exit = _4_})
end
return {execute = execute}
