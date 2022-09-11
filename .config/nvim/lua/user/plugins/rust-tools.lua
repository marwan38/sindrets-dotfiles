return function()
  local rt = require("rust-tools")
  local config = require("user.lsp").create_config()

  rt.setup({
    server = {
      on_attach = config.on_attach
    }
  })
end
