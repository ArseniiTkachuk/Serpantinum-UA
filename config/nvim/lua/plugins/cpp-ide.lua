return {
  -- 1. Mason: менеджер LSP-серверів, форматерів тощо
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  -- 2. Mason-LSPConfig: міст між Mason та налаштуванням LSP
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd" }, -- Автоматично встановить clangd, якщо його немає
      })
    end,
  },

  -- 3. Nvim-LSPConfig: налаштування мовних серверів
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      -- Плагін автодоповнення для LSP
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Налаштування для C/C++ через clangd
      lspconfig.clangd.setup({
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
        },
      })
    end,
  },

  -- 4. Nvim-Cmp: саме віконце підказок (автодоповнення)
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      -- Двигун випадаючих сніпетів (щоб підказки розгорталися)
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(), -- Викликати підказки вручну
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true5 }), -- Підтвердити вибір Enter
          
          -- Навігація стрілками або Tab/S-Tab по списку підказок
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_previous_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump_jump(-1)
            else
              fallback()
            end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- Підказки від C++ (clangd)
          { name = "luasnip" },  -- Сніпети
        }, {
          { name = "buffer" },   -- Слова з поточного файлу
          { name = "path" },     -- Шляхи до файлів
        }),
      })
    end,
  },
}
