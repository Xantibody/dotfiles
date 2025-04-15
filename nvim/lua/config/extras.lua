-- JDTLSのためにしかたなく
vim.env.JAVA_HOME = "/Library/Java/JavaVirtualMachines/jdk-17.jdk/Contents/Home/"

-- skkltonのため
local fcitx = {}

function fcitx.disable()
  os.execute("fcitx5-remote -c")
end

function fcitx.enable()
  os.execute("fcitx5-remote -o")
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = fcitx.disable,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = fcitx.enable,
})
