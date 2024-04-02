--[[
 THESE ARE EXAMPLE CONFIGS FEEL FREE TO CHANGE TO WHATEVER YOU WANT
 `lvim` is the global options object
]]
-- vim options
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.relativenumber = false
vim.wo.wrap = true
vim.wo.linebreak = true
vim.opt.termguicolors = true
-- vim.wo.list = false

-- general
lvim.log.level = "info"
lvim.format_on_save = {
  enabled = true,
  pattern = "*.lua",
  timeout = 1000,
}
-- to disable icons and use a minimalist setup, uncomment the following
-- lvim.use_icons = false

-- keymappings <https://www.lunarvim.org/docs/configuration/keybindings>
lvim.leader = "space"
-- add your own keymapping
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"

-- lvim.keys.normal_mode["<S-l>"] = ":BufferLineCycleNext<CR>"
-- lvim.keys.normal_mode["<S-h>"] = ":BufferLineCyclePrev<CR>"

-- -- Use which-key to add extra bindings with the leader-key prefix
-- lvim.builtin.which_key.mappings["W"] = { "<cmd>noautocmd w<cr>", "Save without formatting" }
-- lvim.builtin.which_key.mappings["P"] = { "<cmd>Telescope projects<CR>", "Projects" }

-- -- Change theme settings
-- lvim.colorscheme = "lunar"

lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "left"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false

------------------------------------------------
-- Plugins and their settings
------------------------------------------------
lvim.plugins = {
  { "mfussenegger/nvim-lint" },
  { "dgagn/diagflow.nvim",         event = 'LspAttach',                              opts = {} },
  { "folke/trouble.nvim",          dependencies = { "nvim-tree/nvim-web-devicons" }, },
  { "simrat39/rust-tools.nvim",    name = "rust-tools" },
  { "j-hui/fidget.nvim",           version = "v1.0.0",                               name = "fidget" },
  { "yuchanns/shfmt.nvim" },
  { "apple/pkl-neovim" },
  { "NoahTheDuke/vim-just" },
  { "IndianBoy42/tree-sitter-just" },
  -- {
  --   'Wansmer/symbol-usage.nvim',
  --   event = 'BufReadPre', -- need run before LspAttach if you use nvim 0.9. On 0.10 use 'LspAttach'
  --   config = function()
  --     require('symbol-usage').setup(
  --       {
  --         filetypes = {
  --           elixir = {
  --             symbol_request_pos = 'start',
  --           },
  --         },
  --       }
  --     )
  --   end
  -- },
  {
    "saecki/crates.nvim",
    version = "v0.3.0",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("crates").setup {
        null_ls = {
          enabled = true,
          name = "crates.nvim",
        },
        popup = {
          border = "rounded",
        },
      }
    end,
  },
  {
    "mrjones2014/nvim-ts-rainbow",
    enable = true,
    extended_mode = true,
    max_file_lines = 20000
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- this will only start session saving when an actual file was opened
    config = function()
      require("persistence").setup {
        dir = vim.fn.expand(vim.fn.stdpath "config" .. "/session/"),
        options = { "buffers", "curdir", "tabpages", "winsize" },
      }
    end,
  },
  -- {
  --   "ray-x/lsp_signature.nvim",
  --   event = "VeryLazy",
  --   opts = {},
  --   config = function(_, opts) require 'lsp_signature'.setup(opts) end
  -- },
  { "ntpeters/vim-better-whitespace" },
  { "onsails/lspkind.nvim" },
  {
    "romgrk/nvim-treesitter-context",
    config = function()
      require("treesitter-context").setup {
        enable = true,   -- Enable this plugin (Can be enabled/disabled later via commands)
        throttle = true, -- Throttles plugin updates (may improve performance)
        max_lines = 0,   -- How many lines the window should span. Values <= 0 mean no limit.
        patterns = {
          -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
          -- For all filetypes
          -- Note that setting an entry here replaces all other patterns for this entry.
          -- By setting the 'default' entry below, you can control which nodes you want to
          -- appear in the context window.
          default = {
            'class',
            'function',
            'method',
            'def',
          },
        },
      }
    end
  },
  {
    "rmagatti/goto-preview",
    config = function()
      require("goto-preview").setup({
        width = 100,
        height = 30,
        default_mappings = true,
      })
    end
  },
  {
    "ray-x/go.nvim",
    dependencies = { -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup({
        max_line_len = 100
      })
    end,
    event = { "CmdlineEnter" },
    ft = { "go", 'gomod' },
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  {
    "folke/todo-comments.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    event = "BufRead",
    config = function()
      require("todo-comments").setup {
        highlight = {
          after = "",
          before = "",
          multiline = false,
          multiline_context = 0,
          pattern = [[.*<(KEYWORDS)\s*]],
        }
      }
    end,
  },
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({ "css", "scss", "html", "javascript" }, {
        RGB = true,      -- #RGB hex codes
        RRGGBB = true,   -- #RRGGBB hex codes
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        rgb_fn = true,   -- CSS rgb() and rgba() functions
        hsl_fn = true,   -- CSS hsl() and hsla() functions
        css = true,      -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true,   -- Enable all CSS *functions*: rgb_fn, hsl_fn
      })
    end,
  },
  { "tpope/vim-eunuch" },
  -- { "navarasu/onedark.nvim" },
  { "catppuccin/nvim", name = "catppuccin" },
}

-- Setup / load the `onedark` theme.
-- require('onedark').setup {
--   style = 'darker'
-- }
-- require('onedark').load()

-- Enable rainbow brackets / parentheses.
lvim.builtin.treesitter.rainbow.enable = true

require('lspkind').init({
  -- defines how annotations are shown
  -- default: symbol
  -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
  mode = 'symbol_text',

  -- default symbol map
  -- can be either 'default' (requires nerd-fonts font) or
  -- 'codicons' for codicon preset (requires vscode-codicons font)
  --
  -- default: 'default'
  preset = 'codicons',

  -- override preset symbols
  --
  -- default: {}
  symbol_map = {
    Text = "󰉿",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰜢",
    Variable = "󰀫",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "󰑭",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "󰈇",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "󰙅",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "",
  },
})

-- require("fidget").setup()
-- require "lsp_signature".setup({})

require("shfmt").setup({
  -- Default configs
  cmd = "shfmt",
  args = { "-l", "-w" },
  auto_format = true,
})

require('lint').linters_by_ft = {
  clojure = { 'clj-kondo' },
  cmakefile = { 'cmakelint' },
  cpp = { 'clangtidy', 'cppcheck', 'cpplint', 'flawfinder' },
  css = { 'stylelint' },
  dotenv = { 'dotenv_linter' },
  elixir = { 'credo' },
  dockerfile = { 'hadolint', 'trivy' },
  haskell = { 'hlint' },
  go = { 'golangcilint', 'revive' },
  java = { 'checkstyle' },
  javascript = { 'biomejs', 'eslint', 'jshint', 'standardjs' },
  json = { 'jsonlint' },
  jsx = { 'biomejs' },
  kotlin = { 'ktlint' },
  latex = { 'chktex', 'lacheck' },
  lua = { 'luacheck', 'selene' },
  markdown = { 'markdownlint', 'vale', },
  nix = { 'nix', 'statix' },
  perl = { 'checkpatch', 'perlcritic', 'perlimports' },
  php = { 'php', 'phpcs', 'phpinsights', 'phpmd', 'phpstan', 'psalm' },
  proto = { 'buf_lint' },
  python = { 'bandit', 'flake8', 'mypy', 'pycodestyle', 'pydocstyle', 'pylint', 'ruff', 'vulture' },
  ruby = { 'ruby', 'rubocop', 'standardrb' },
  shell = { 'shellcheck' },
  sql = { 'sqlfluff' },
  typescript = { 'biomejs' },
  yaml = { 'yamllint' },
  zsh = { 'zsh' },
}

------------------------------------------------
-- Treesitter settings
------------------------------------------------

-- Automatically install missing parsers when entering buffer
lvim.builtin.treesitter.auto_install = true

lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "c_sharp",
  "css",
  "cpp",
  "dockerfile",
  "eex",
  "elixir",
  "erlang",
  "gitignore",
  "go",
  "gomod",
  "gosum",
  "gowork",
  "heex",
  "html",
  "java",
  "javascript",
  "json",
  "json5",
  "lua",
  "make",
  "markdown",
  "ocaml",
  "ocaml_interface",
  "php",
  "python",
  "ruby",
  "rust",
  "sql",
  "terraform",
  "toml",
  "typescript",
  "tsx",
  "v",
  "yaml",
  "zig"
}
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true

------------------------------------------------
-- LSP settings
------------------------------------------------

lvim.lsp.installer.setup.ensure_installed = {
  "bashls",
  "cssls",
  "dockerls",
  "elixirls",
  "erlangls",
  "eslint", -- Javascript, Typescript
  "gopls",  -- Golang
  "html",
  "jsonls",
  "lemminx",  -- XML
  "marksman", -- Markdown
  -- "ocaml",
  "pyright",  -- Python
  "rust_analyzer",
  "sqlls",
  "taplo",    -- TOML
  "tsserver", -- Javascript, Typescript
  "vimls",
  "yamlls",
  "zk", -- Markdown
  "zls" -- Zig
}

-- Format on save.
lvim.format_on_save = {
  enabled = true
}

require("lvim.lsp").setup()

-- LSP: Golang
-- This is doing extra formatting on save (using `golines` in this case)
local format_sync_grp = vim.api.nvim_create_augroup("GoImport", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  command = 'GoFmt',
  group = format_sync_grp,
})

-- LSP: Rust
local lspc = require('lspconfig')

-- local on_attach = function(client)
--   require('completion').on_attach(client)
-- end

lspc.rust_analyzer.setup {
  -- on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      assist = {
        importMergeBehavior = "crate",
        importPrefix = "by_self",
      },
      cargo = {
        buildScripts = {
          enable = true,
        },
        loadOutDirsFromCheck = true
      },
      checkOnSave = {
        command = "clippy"
      },
      diagnostics = {
      },
      imports = {
        granularity = {
          group = "module",
        },
        prefix = "self",
      },
      procMacro = {
        enable = true
      },
    }
  }
}

-- Rust tools
local rt = require('rust-tools')
rt.setup({
  server = {
    on_attach = function(client, bufnr)
      require("lvim.lsp").common_on_attach(client, bufnr)
      vim.keymap.set("n", "K", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Hover actions
      vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
      -- Code action groups
      vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
    end,
    capabilities = require("lvim.lsp").common_capabilities(),
    settings = {
      ["rust-analyzer"] = {
        lens = {
          enable = true,
        },
        checkOnSave = {
          enable = true,
          command = "clippy",
        },
      },
    },
  },
})

rt.inlay_hints.enable()
rt.runnables.runnables()
rt.move_item.move_item(true)

-- Leave these disabled because they don't seem to be valid or existing.
-- rt.hover_range.hover_range()
-- rt.parent_module.parent_module()
-- rt.join_lines.join_lines()

-- LSP: Elixir
local homedir = os.getenv("HOME")
local root_pattern = require("lspconfig").util.root_pattern

require 'lspconfig'.elixirls.setup {
  filetypes = { "elixir", "eelixir", "heex", "surface" },
  root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
  cmd = { homedir .. "/bin/elixir-ls/release/language_server.sh" },
}

-- (1) add `elixirls` to `skipped_servers` list
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "elixirls" })

-- (2) remove `lexical` from `skipped_servers` list
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "lexical"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- (3) configure `lexical`
-- local lspconfig = require("lspconfig")
-- local configs = require("lspconfig.configs")

-- local lexical_config = {
--   filetypes = { "elixir", "eelixir", "heex", "surface" },
--   cmd = { "/Users/dimi/bin/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
--   settings = {},
-- }

-- if not configs.lexical then
--   configs.lexical = {
--     default_config = {
--       filetypes = lexical_config.filetypes,
--       cmd = lexical_config.cmd,
--       root_dir = function(fname)
--         return lspconfig.util.root_pattern("mix.exs", ".git")(fname) or vim.loop.os_homedir()
--       end,
--       -- optional settings
--       settings = lexical_config.settings,
--     },
--   }
-- end

-- lspconfig.lexical.setup({})

-- require 'lspconfig'.lexical.setup {
--   filetypes = { "elixir", "eelixir", "heex" },
--   root_dir = root_pattern("mix.exs", ".git") or vim.loop.os_homedir(),
--   cmd = { homedir .. "/bin/lexical/_build/dev/package/lexical/bin/start_lexical.sh" },
-- }

------------------------------------------------
-- Telescope settings.
------------------------------------------------

local actions = require("telescope.actions")

lvim.builtin.telescope.pickers = {
  buffers = {
    --
    -- Setting theme to "dropdown" makes the buffer selector smaller and centered.
    -- I like the selector like all others -- big and with prompt at the bottom -- so this
    -- will stay commented out for the moment.
    --
    -- theme = "dropdown",
    --
    -- Puzzlingly, `previewer = true` crashes the preview settings.
    --
    -- previewer = true,
    initial_mode = "insert",
    mappings = {
      i = {
        ["<C-d>"] = actions.delete_buffer,
      },
      n = {
        ["dd"] = actions.delete_buffer,
      },
    },
    scroll_strategy = "limit",
  },
}

lvim.builtin.telescope.defaults.scroll_strategy = "limit"
lvim.builtin.telescope.defaults.layout_config = {
  -- prompt_position = "top",
  height = 0.95,
  width = 0.95,
  bottom_pane = {
    height = 25,
    preview_cutoff = 120,
  },
  center = {
    height = 0.4,
    preview_cutoff = 40,
    width = 0.5,
  },
  cursor = {
    preview_cutoff = 40,
  },
  horizontal = {
    preview_cutoff = 120,
    preview_width = 0.6,
  },
  vertical = {
    preview_cutoff = 40,
  },
  flex = {
    flip_columns = 150,
  },
}

lvim.builtin.telescope.theme = "center"
lvim.builtin.telescope.defaults.initial_mode = "insert"
-- lvim.builtin.telescope.defaults.sorting_strategy = "ascending"
lvim.builtin.telescope.defaults.layout_strategy = "flex"
lvim.builtin.telescope.defaults.prompt_prefix = "  "
lvim.builtin.telescope.defaults.selection_caret = "❯ "
lvim.builtin.telescope.defaults.mappings.i["<esc>"] = actions.close
lvim.builtin.telescope.defaults.winblend = 10

-- This gives us previewing of files when looking through project files.
lvim.builtin.which_key.mappings.f = {
  "<cmd>Telescope find_files<cr>",
  "Project files"
}

-- Show previewer when searching buffers with <leader>bf
lvim.builtin.which_key.mappings.b.f = {
  "<cmd>Telescope buffers<cr>",
  "Buffers"
}

-- Session
lvim.builtin.which_key.mappings["S"] = {
  name = "Session",
  c = { "<cmd>lua require('persistence').load()<cr>", "Restore last session for current dir" },
  l = { "<cmd>lua require('persistence').load({ last = true })<cr>", "Restore last session" },
  Q = { "<cmd>lua require('persistence').stop()<cr>", "Quit without saving session" },
}

lvim.builtin.which_key.mappings["x"] = {
  name = "Trouble",
  x = { "<cmd>lua require('trouble').toggle()<cr>", "Toggle list of troubles" },
  w = { "<cmd>lua require('trouble').toggle('workspace_diagnostics')<cr>", "Workspace diagnostics" },
  d = { "<cmd>lua require('trouble').toggle('document_diagnostics')<cr>", "Document diagnostics" },
  q = { "<cmd>lua require('trouble').toggle('quickfix')<cr>", "Quick fix" },
  l = { "<cmd>lua require('trouble').toggle('loclist')<cr>", "Loclist" },
  r = { "<cmd>lua require('trouble').toggle('lsp_references')<cr>", "LSP References" },
  -- j = { "<cmd>lua require('trouble').next({skip_groups = true, jump = true})<cr>", "Next" },
  -- k = { "<cmd>lua require('trouble').previous({skip_groups = true, jump = true})<cr>", "Next" },
}

--
-- END OF USER CONFIG HERE.
--


-- lvim.builtin.treesitter.ignore_install = { "haskell" }

-- -- always installed on startup, useful for parsers without a strict filetype
-- lvim.builtin.treesitter.ensure_installed = { "comment", "markdown_inline", "regex" }

-- -- generic LSP settings <https://www.lunarvim.org/docs/languages#lsp-support>

-- --- disable automatic installation of servers
-- lvim.lsp.installer.setup.automatic_installation = false

-- ---configure a server manually. IMPORTANT: Requires `:LvimCacheReset` to take effect
-- ---see the full default list `:lua =lvim.lsp.automatic_configuration.skipped_servers`
-- vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "pyright" })
-- local opts = {} -- check the lspconfig documentation for a list of all possible options
-- require("lvim.lsp.manager").setup("pyright", opts)

-- ---remove a server from the skipped list, e.g. eslint, or emmet_ls. IMPORTANT: Requires `:LvimCacheReset` to take effect
-- ---`:LvimInfo` lists which server(s) are skipped for the current filetype
-- lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
--   return server ~= "emmet_ls"
-- end, lvim.lsp.automatic_configuration.skipped_servers)

-- -- you can set a custom on_attach function that will be used for all the language servers
-- -- See <https://github.com/neovim/nvim-lspconfig#keybindings-and-completion>
-- lvim.lsp.on_attach_callback = function(client, bufnr)
--   local function buf_set_option(...)
--     vim.api.nvim_buf_set_option(bufnr, ...)
--   end
--   --Enable completion triggered by <c-x><c-o>
--   buf_set_option("omnifunc", "v:lua.vim.lsp.omnifunc")
-- end

-- -- linters, formatters and code actions <https://www.lunarvim.org/docs/languages#lintingformatting>
-- local formatters = require "lvim.lsp.null-ls.formatters"
-- formatters.setup {
--   { command = "stylua" },
--   {
--     command = "prettier",
--     extra_args = { "--print-width", "100" },
--     filetypes = { "typescript", "typescriptreact" },
--   },
-- }
-- local linters = require "lvim.lsp.null-ls.linters"
-- linters.setup {
--   { command = "flake8", filetypes = { "python" } },
--   {
--     command = "shellcheck",
--     args = { "--severity", "warning" },
--   },
-- }
-- local code_actions = require "lvim.lsp.null-ls.code_actions"
-- code_actions.setup {
--   {
--     exe = "eslint",
--     filetypes = { "typescript", "typescriptreact" },
--   },
-- }

-- -- Additional Plugins <https://www.lunarvim.org/docs/plugins#user-plugins>
-- lvim.plugins = {
--     {
--       "folke/trouble.nvim",
--       cmd = "TroubleToggle",
--     },
-- }

-- -- Autocommands (`:help autocmd`) <https://neovim.io/doc/user/autocmd.html>
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "zsh",
--   callback = function()
--     -- let treesitter use bash highlight for zsh files as well
--     require("nvim-treesitter.highlight").attach(0, "bash")
--   end,
-- })
