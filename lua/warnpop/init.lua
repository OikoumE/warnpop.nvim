local M = {
  buf = vim.api.nvim_create_buf(false, true), -- listed =false, scratch =true
  win = -1,
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
}
M.keymap_set = function()
  vim.keymap.set("n", "]e", M.goto_last_diag, { desc = "goto next [E]rror" })
  require("which-key").add({ { "]e", M.goto_last_diag, desc = "goto next [E]rror", mode = "n" } })
end
M.goto_last_diag = function()
  local diag = M.last_diag
  if not diag.active or not vim.api.nvim_buf_is_valid(diag.diagnostic.bufnr) then
    vim.notify("No error to jump to!", vim.log.levels.WARN)
    return
  end
  -- switch buffer
  vim.api.nvim_set_current_buf(diag.diagnostic.bufnr)
  -- jump to line
  vim.api.nvim_win_set_cursor(0, { diag.diagnostic.lnum + 1, diag.diagnostic.col })
end
M.ns = vim.api.nvim_create_namespace(M.nsName)
M.create_autocmd = function(win_opts)
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function(args)
      -- TODO : dont know if this is fired ONCE with all data
      -- or multiple times with different datas
      -- we are not collecting data and comparing with old/new
      -- so might be misrepresenting number of errors across project
      -- and only show per buffer

      local diag_count = { error = 0, warning = 0 }
      local diagnostics = vim.diagnostic.get(args.buf)
      for _, diag in ipairs(diagnostics) do
        if diag.severity == vim.diagnostic.severity.ERROR then
          -- TODO: check if "In included file:"
          if not diag.message:find("In included file:") then
            M.last_diag = { diagnostic = diag, args = args, active = true }
          end
          M.last_diag.active = true
          diag_count.error = diag_count.error + 1
        elseif diag.severity == vim.diagnostic.severity.WARN then
          diag_count.warning = diag_count.warning + 1
        end
      end
      if diag_count.error > 0 and diag_count.warning > 0 then
        if not vim.api.nvim_win_is_valid(M.win) then
          M.win = vim.api.nvim_open_win(M.buf, false, win_opts or M.default_win_opts) -- diag_count.error
        end
        local errStr = "-  Err:" .. diag_count.error .. "   Warn:" .. diag_count.warning .. "  -"
        local errLen = #errStr --vim.fn.strwidth(errStr)
        local errMid = math.floor(errLen / 2)
        vim.bo[M.buf].modifiable = true
        vim.api.nvim_buf_set_lines(M.buf, -2, -1, false, { errStr })
        vim.bo[M.buf].modifiable = false
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 2, { end_col = errMid - 1, hl_group = M.eHl })
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, errMid, { end_col = errLen - 2, hl_group = M.wHl })
        vim.api.nvim_win_set_width(M.win, errLen)
      elseif vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
        diag_count = { error = 0, warning = 0 }
        M.last_diag.active = false
      end
    end,
  })
end
M.setup = function(win_opts)
  M.keymap_set()
  vim.api.nvim_set_hl(0, M.eHl, { bg = "#FF0000", fg = "Cyan" })
  vim.api.nvim_set_hl(0, M.wHl, { bg = "#FFFF00", fg = "Blue" })
  M.create_autocmd(win_opts)
  vim.bo[M.buf].buftype = "nofile"
  vim.bo[M.buf].bufhidden = "hide"
  vim.bo[M.buf].swapfile = false
end

return M
