print("Hello world!")

local M = {
  buf = vim.api.nvim_create_buf(false, true), -- listed =false, scratch =true
  win = -1,
  default_win_opts = {
    relative = "editor",
    width = 15,
    height = 1,
    row = 0, --vim.o.lines,
    col = vim.o.columns / 2,
    style = "minimal",
    border = "none",
    focusable = false,
  },
}
M.setup = function(win_opts)
  vim.api.nvim_buf_set_var(M.buf, "modifiable", false)
  -- show shit in status line
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    callback = function(args)
      local diag_count = { error = 0, warning = 0 }
      local diagnostics = vim.diagnostic.get(args.buf)
      for i, diag in ipairs(diagnostics) do
        print(string.format("Diag %d: [%d] %s", i, diag.severity, diag.message))
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
        vim.api.nvim_buf_set_lines(
          M.buf,
          -2,
          -1,
          false,
          { "Err:" .. diag_count.error .. " Warn:" .. diag_count.warning }
        )
      elseif vim.api.nvim_win_is_valid(M.win) then
        vim.api.nvim_win_close(M.win, true)
        diag_count = { error = 0, warning = 0 }
      end
    end,
  })
end

return M
