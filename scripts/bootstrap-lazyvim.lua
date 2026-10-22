-- Called only for a starter created by install-neovim.sh. Never exits while
-- requested plugin/package/parser installs are merely queued in the background.
local function run()
  local lazy = require("lazy")
  lazy.install({ wait = true, show = false })

  local function check_plugins()
    local errors = {}
    for name, plugin in pairs(require("lazy.core.config").plugins) do
      if not plugin._.installed then
        errors[#errors + 1] = "missing plugin: " .. name
      end
      for _, task in ipairs(plugin._.tasks or {}) do
        if task:has_errors() then
          errors[#errors + 1] = "failed plugin task: " .. name
        end
      end
    end
    assert(#errors == 0, table.concat(errors, "\n"))
  end
  check_plugins()

  lazy.load({ plugins = { "mason.nvim", "nvim-lspconfig", "nvim-treesitter" } })
  local registry = require("mason-registry")
  local refreshed, refresh_ok = false, false
  registry.refresh(function(ok)
    refresh_ok, refreshed = ok, true
  end)
  assert(vim.wait(180000, function() return refreshed end, 100), "Mason registry refresh timed out")
  assert(refresh_ok, "Mason registry refresh failed")

  local names = {
    "jdtls", "vtsls", "pyright", "ruff", "gopls", "rust-analyzer",
    "lua-language-server", "stylua", "shfmt", "goimports", "gofumpt", "codelldb",
  }
  -- Include the starter's default/extra tool requirements as they evolve.
  for _, name in ipairs(LazyVim.opts("mason.nvim").ensure_installed or {}) do
    if not vim.tbl_contains(names, name) then names[#names + 1] = name end
  end
  local failures = {}
  registry:on("package:install:failed", function(pkg)
    failures[pkg.name] = true
  end)
  local packages = {}
  for _, name in ipairs(names) do
    local pkg = registry.get_package(name)
    packages[#packages + 1] = pkg
    if not pkg:is_installed() and not pkg:is_installing() then
      print("Installing Mason package: " .. name)
      pkg:install()
    end
  end
  local function all_packages_done()
    for _, pkg in ipairs(packages) do
      if not pkg:is_installed() or pkg:is_installing() then return false end
    end
    return true
  end
  local done = vim.wait(1200000, function()
    return next(failures) ~= nil or all_packages_done()
  end, 200)
  assert(next(failures) == nil, "Mason installation failed: " .. table.concat(vim.tbl_keys(failures), ", "))
  local missing = {}
  for _, pkg in ipairs(packages) do
    if not pkg:is_installed() or pkg:is_installing() then missing[#missing + 1] = pkg.name end
  end
  assert(done and #missing == 0, "Mason installation timed out: " .. table.concat(missing, ", "))

  local ts = require("nvim-treesitter")
  assert(type(ts.get_installed) == "function", "Unsupported nvim-treesitter API; inspect :Lazy and :TSLog")
  local parsers = LazyVim.opts("nvim-treesitter").ensure_installed or {}
  for _, lang in ipairs({ "java", "javascript", "typescript", "tsx", "python", "go", "rust" }) do
    if not vim.tbl_contains(parsers, lang) then parsers[#parsers + 1] = lang end
  end
  ts.install(parsers, { summary = true }):wait(600000)
  local parsers_done = vim.wait(600000, function()
    local installed = ts.get_installed()
    for _, lang in ipairs(parsers) do
      if not vim.tbl_contains(installed, lang) then return false end
    end
    return true
  end, 200)
  assert(parsers_done, "Tree-sitter parser installation timed out; inspect :TSLog")
  check_plugins()
  print("Completed LazyVim plugin, Mason package, and Tree-sitter installation.")
end

local ok, message = xpcall(run, debug.traceback)
if not ok then
  io.stderr:write("LazyVim bootstrap error:\n" .. tostring(message) .. "\n")
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
