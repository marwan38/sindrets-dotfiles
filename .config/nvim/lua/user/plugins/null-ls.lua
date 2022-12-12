return function()
  local nls = require("null-ls")
  local builtins = nls.builtins

  -- code action sources
  local code_actions = builtins.code_actions
  -- diagnostic sources
  local diagnostics = builtins.diagnostics
  -- formatting sources
  local formatting = builtins.formatting

  local common_config = {
    method = nls.methods.DIAGNOSTICS_ON_SAVE
  }

  local function with_common_config(builtin)
    builtin.with(common_config)
  end

  nls.setup({
    temp_dir = '/tmp',
    sources = {
      diagnostics.ansiblelint,
      diagnostics.markdownlint,
      diagnostics.stylelint,
      diagnostics.phpcs.with {
        command = "./vendor/bin/phpcs",
      },
      diagnostics.phpstan.with {
        command = "./vendor/bin/phpstan",
        -- condition = function(utils)
        --   return utils.root_has_file "phpstan.neon"
        -- end,
      },
      diagnostics.yamllint,
      diagnostics.zsh,


      formatting.prettier,
      formatting.stylelint.with {
        filetypes = { "scss", "less", "css", "sass", "typescript", "typescriptreact" },
        command = "./node_modules/.bin/stylelint",
      },
      formatting.phpcbf.with {
        command = "./vendor/bin/phpcbf",
      },
      formatting.phpcsfixer.with {
        command = "./vendor/bin/php-cs-fixer",
        args = {
          "--no-interaction",
          "--quiet",
          "--config=./scripts/php/.php-cs-fixer.php",
          "fix",
          "$FILENAME",
        },
      },
      formatting.mdformat,
      formatting.shfmt
    }
  })
end
