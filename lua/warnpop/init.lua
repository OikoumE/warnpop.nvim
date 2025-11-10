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
}

M.ns = vim.api.nvim_create_namespace(M.nsName)
vim.api.nvim_set_hl(0, M.eHl, { bg = "#FF0000", fg = "Cyan" })
vim.api.nvim_set_hl(0, M.wHl, { bg = "#FFFF00", fg = "Blue" })
M.setup = function(win_opts)
  vim.api.nvim_buf_set_var(M.buf, "modifiable", false)
  -- show shit in status line
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function(args)
      local diag_count = { error = 0, warning = 0 }
      local diagnostics = vim.diagnostic.get(args.buf)
      for i, diag in ipairs(diagnostics) do
        if diag.severity == vim.diagnostic.severity.ERROR then
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
        vim.api.nvim_buf_set_lines(M.buf, -2, -1, false, { errStr })
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, 2, { end_col = errMid - 1, hl_group = M.eHl })
        vim.api.nvim_buf_set_extmark(M.buf, M.ns, 0, errMid, { end_col = errLen - 2, hl_group = M.wHl })

        vim.api.nvim_win_set_width(M.win, errLen)
        -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#FF0000", fg = "#D8DEE9" }) -- Example: set custom background and foreground
      elseif vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
        diag_count = { error = 0, warning = 0 }
      end
    end,
  })
end

return M
