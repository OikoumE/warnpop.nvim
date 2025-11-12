local severity = vim.diagnostic.severity
local M = {
  buf = -1, -- listed =false, scratch =true
  win = -1,
  win_opts = {},
  default_win_opts = {
    relative = "editor",
    width = 17,
    height = 1,
    row = 0, --vim.o.lines,
    col = vim.o.columns / 2,
    style = "minimal",
    border = "none",
    focusable = false,
  },
  nsName = "Warnpop",
  eHl = "ErrorHighlight",
  wHl = "WarnHighlight",
  last_diag = { diagnostic = {}, args = {}, active = false },
  diags = {},
}
M.keymap_set = function()
  vim.keymap.set("n", "]e", M.goto_last_diag, { desc = "goto next [E]rror" })
  require("which-key").add({ { "]e", M.goto_last_diag, desc = "goto next [E]rror", mode = "n" } })
end
M.goto_last_diag = function()
  local diag = M.last_diag
  if not diag.active or not vim.api.nvim_buf_is_valid(diag.diagnostic.bufnr) then
    vim.notify("No error to jump to!", severity.WARN)
    return
  end
  -- switch buffer
  vim.api.nvim_set_current_buf(diag.diagnostic.bufnr)
  -- jump to line
  vim.api.nvim_win_set_cursor(0, { diag.diagnostic.lnum + 1, diag.diagnostic.col })
end
M.create_string = function()
  local hasJumpTarget = ""
  if vim.api.nvim_buf_is_valid(M.last_diag.args.buf) then
    hasJumpTarget = "*"
  end
  local errStr = "-  Err:" .. #M.diags .. hasJumpTarget .. "  -"
  return #errStr, errStr
end
M.create_buf = function()
  print("diags:" .. tostring(#M.diags))
  if #M.diags > 0 then
    local errLen, errStr = M.create_string()
    if not vim.api.nvim_buf_is_valid(M.buf) then
      M.buf = vim.api.nvim_create_buf(false, true) -- listed =false, scratch =true
      vim.api.nvim_buf_set_lines(M.buf, -2, -1, false, { errStr })
      vim.bo[M.buf].modifiable = false
      vim.bo[M.buf].buftype = "nofile"
      vim.bo[M.buf].bufhidden = "wipe"
      vim.bo[M.buf].swapfile = false
      vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 2, { end_col = errLen - 2, hl_group = M.eHl })
    end
    if not vim.api.nvim_win_is_valid(M.win) then
      M.win = vim.api.nvim_open_win(M.buf, false, M.win_opts)
    end
    vim.api.nvim_win_set_width(M.win, errLen)
  else
    if vim.api.nvim_buf_is_valid(M.buf) then
      vim.cmd("bd " .. M.buf)
    end
    if vim.api.nvim_win_is_valid(M.win) then
      vim.api.nvim_win_close(M.win, true)
    end
    M.last_diag.active = false
    vim.notify("closing win!" .. tostring(#M.diags))
    print("closing win!" .. tostring(#M.diags))
  end
end
M.ns = vim.api.nvim_create_namespace(M.nsName)
M.create_autocmd = function()
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function(args)
      local diagnostics = vim.diagnostic.get(args.buf)
      --Fields `bufnr`, `end_lnum`, `end_col`, and `severity`
      M.diags = {}
      for _, diag in ipairs(diagnostics) do
        if diag.severity == severity.ERROR then
          -- TODO: check if "In included file:"
          if not diag.message:find("In included file:") and not M.last_diag.active then
            M.last_diag = { diagnostic = diag, args = args, active = true }
          end
          table.insert(M.diags, { diagnostic = diag, args = args, active = true })
          M.last_diag.active = true
        end
      end
      M.create_buf()
    end,
  })
end
M.setup = function(win_opts)
  M.win_opts = win_opts or M.default_win_opts
  M.keymap_set()
  vim.api.nvim_set_hl(0, M.eHl, { bg = "#FF0000", fg = "Cyan" })
  vim.api.nvim_set_hl(0, M.wHl, { bg = "#FFFF00", fg = "Blue" })
  M.create_autocmd()
end

return M
