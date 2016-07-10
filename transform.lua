local strict = require "std.strict"
local _ENV = strict (_G)

package.path=package.path .. ';?.lua'
require 'dsl'

local M = {}

local function clone_table(t)
  local nt = {}
  for i,v in pairs(t) do
    nt[i] = v
  end
  return nt
end

local function rotate_nodes(l, r)
  assert(l)
  assert(r)

  l.arg2, l.arg1, r.arg1, r.arg2 = r.arg2, l.arg2, l.arg1, r.arg1
end

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
      if n.type == 'bin_op' and AssocOps[n.bin_op] and n.bin_op == n.arg1.bin_op then
        return { n_l = n.arg1, n_r = n}
      end
    end,
    apply = function(s)
      local nl = clone_table(s.n_l)
      s.n_r.arg1 = nl
      rotate_nodes(nl, s.n_r)
    end
  },
  assoc_r = {
    match = function(n)
      if n.type == 'bin_op' and AssocOps[n.bin_op] and n.bin_op == n.arg2.bin_op then
        return { n_l = n, n_r = n.arg2 }
      end
    end,
    apply = function(s)
      local nr = clone_table(s.n_r)
      s.n_l.arg2 = nr

      rotate_nodes(s.n_l, nr)
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
