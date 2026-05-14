return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "moll/vim-bbye",
  },
  opts = {
    options = {
      close_command = "Bdelete! %d",
      right_mouse_command = "Bdelete! %d",
      diagnostics = "nvim_lsp",
      offsets = {
        { filetype = "NvimTree", text = "Explorer", separator = true, text_align = "left" },
      },
      show_buffer_close_icons = true,
      show_close_icon = false,
      always_show_bufferline = true,
    },
  },
}
