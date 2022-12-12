return function()
  require("neorg").setup({
    load = {
      ["core.defaults"] = {
        config = {
          disable = {
            "core.norg.esupports.indent",
          },
        },
      },
      ["core.norg.qol.toc"] = {},
      ['core.integrations.telescope'] = {},
      ['core.norg.concealer'] = {},
      ["core.export"] = {},
      ["core.norg.dirman"] = {
        config = {
          workspaces = {
            work_notes = "~/Documents/notes",
          },
        },
      },
      ["core.norg.completion"] = {
        config = {
          engine = "nvim-cmp",
        },
      },
      ['core.gtd.base'] = {
        config = {
          workspace = 'work_notes',
        },
      },
    },
  })
end
