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
  }
}

function M.find_transform_sites(graph)
  local sites = {}

  local function detect_possibility(n)
    for name, rule in pairs(TransformRules) do
      if rule.match(n) then
        table.insert(sites, { rule = name, place = n})
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
