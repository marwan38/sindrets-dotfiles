return function()
  local config = Config.lsp.create_config()
  local rt = require("rust-tools")

  rt.setup({
    server = {
      on_attach = config.on_attach
    }
  })
end
