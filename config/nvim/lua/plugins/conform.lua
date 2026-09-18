return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- Завантажувати перед збереженням файлу
  cmd = { "ConformInfo" },
  keys = {
    {
      -- Гаряча клавіша для форматування вручну: <leader>mp (або змініть під себе)
      "<leader>mp",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Форматувати буфер (код)",
    },
  },
  opts = {
    -- Визначення форматерів за мовами
    formatters_by_ft = {
      cpp = { "clang-format" },
      c = { "clang-format" },
      cmake = { "cmake_format" },
      lua = { "stylua" },
      javascript = { "prettier" },
      typescript = { "prettier" },
    },
    -- Форматування автоматично при збереженні файлу
    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true, -- Якщо специфічного форматера немає, спробує через LSP
    },
  },
}
