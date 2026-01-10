# LSP設定とkeymaps
{ pkgs, ... }:
{
  # LSP設定
  plugins.lsp = {
    enable = true;
    servers = {
      nixd.enable = true;
      lua_ls.enable = true;
      gopls.enable = true;
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
      };
      yamlls.enable = true;
      jsonls.enable = true;
      html.enable = true;
      bashls.enable = true;
      pyright.enable = true;
      tinymist.enable = true;
      typos_lsp.enable = true;
      ts_ls.enable = true;
      helm_ls.enable = true;
      denols.enable = true;
      efm.enable = true;
    };
  };

  # LSP keymaps
  keymaps = [
    {
      key = "<leader>d";
      action = "<cmd>lua vim.diagnostic.open_float()<CR>";
      mode = "n";
      options.desc = "Show line diagnostics";
    }
    {
      key = "<leader>D";
      action = "<cmd>lua vim.lsp.buf.type_definition()<CR>";
      mode = "n";
      options.desc = "Go to type definition";
    }
    {
      key = "[d";
      action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
      mode = "n";
      options.desc = "Go to previous diagnostic";
    }
    {
      key = "]d";
      action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
      mode = "n";
      options.desc = "Go to next diagnostic";
    }
    {
      key = "K";
      action = "<cmd>lua vim.lsp.buf.hover()<CR>";
      mode = "n";
      options.desc = "Show documentation for what is under cursor";
    }
    {
      key = "gD";
      action = "<cmd>lua vim.lsp.buf.declaration()<CR>";
      mode = "n";
      options.desc = "Go to declaration";
    }
    {
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      mode = "n";
      options.desc = "Go to definition";
    }
    {
      key = "gi";
      action = "<cmd>lua vim.lsp.buf.implementation()<CR>";
      mode = "n";
      options.desc = "Go to implementation";
    }
    {
      key = "gr";
      action = "<cmd>lua vim.lsp.buf.references()<CR>";
      mode = "n";
      options.desc = "Find references";
    }
    {
      key = "<C-k>";
      action = "<cmd>lua vim.lsp.buf.signature_help()<CR>";
      mode = "n";
      options.desc = "Show signature help";
    }
    {
      key = "<leader>wa";
      action = "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>";
      mode = "n";
      options.desc = "Add workspace folder";
    }
    {
      key = "<leader>wr";
      action = "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>";
      mode = "n";
      options.desc = "Remove workspace folder";
    }
    {
      key = "<leader>wl";
      action = "<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>";
      mode = "n";
      options.desc = "List workspace folders";
    }
    {
      key = "<leader>rs";
      action = "<cmd>LspRestart<CR>";
      mode = "n";
      options.desc = "Restart LSP";
    }
    {
      key = "<leader>rn";
      action = "<cmd>lua vim.lsp.buf.rename()<CR>";
      mode = "n";
      options.desc = "Rename symbol";
    }
  ];

  # LSP Lua設定を読み込む
  extraFiles."lua/plugins/edit/lsp/config.lua".source = ./config.lua;
  extraConfigLua = ''require("plugins.edit.lsp.config")'';
}
