return {
  'gen740/SmoothCursor.nvim',
  opts = {
    texthl = { bg = nil, fg = "#643f61" }
  },
  config = function()
    require('smoothcursor').setup()
  end
}
