local strict = require "std.strict"
local _ENV = strict (_G)

package.path=package.path .. ';?.lua'
require 'dsl'

local M = {}

local TransformRules = {
  commutativity = {
    match = function(n)
      if n.bin_op == Plus or n.bin_op == Mul then
        return n
      end
    end,
    apply = function(n)
      n.arg1, n.arg2 = n.arg2, n.arg1
    end
  },
  assoc_l = {
    match = function(n)
      if n.type == 'bin_op' and n.bin_op == n.arg1.bin_op then
        return { n_l = n.arg1, n_r = n}
      end
    end,
    apply = function(s)
      local l = assert(s.n_l)
      local r = assert(s.n_r)
      l.arg1, l.arg2, r.arg1, r.arg2 = l.arg2, r.arg2, l.arg1, l
    end
  }
}

function M.find_transform_sites(graph)
  local sites = {}

  local function detect_possibility(n)
    for name, rule in pairs(TransformRules) do
      local m = rule.match(n)
      if m then
        table.insert(sites, { rule = name, place = m})
      end
    end
  end

  walk_graph(graph, detect_possibility)

  return sites
end

function M.apply_transform(site)
  local r = assert(TransformRules[site.rule], 'rule not found')
  r.apply(site.place)
end

return M
