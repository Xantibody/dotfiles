return {
    'nvimdev/lspsaga.nvim',
    config = function()
        require('lspsaga').setup({})
    end,
    dependencies = {
        'nvim-treesitter/nvim-treesitter', -- optional
        'nvim-tree/nvim-web-devicons',     -- optional
    },
    keys = {
    {'K', '<cmd>Lspsaga hover_doc', mode ='n', desc = 'hover doc'}
  }
}
