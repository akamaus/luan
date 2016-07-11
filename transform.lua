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
  },
  distrib = {
    match = function(n)
      if n.type == 'bin_op' and n.arg2.type == 'bin_op' then
        for _,p in ipairs(DistrOpPairs) do
          if p[1] == n.bin_op and p[2] == n.arg2.bin_op then
            return n
          end
        end
      end
    end,
    apply = function(n)
      local op_out = n.bin_op
      local op_in = n.arg2.bin_op
      local o1 = BinOp(op_out, n.arg1, n.arg2.arg1)
      local o2 = BinOp(op_out, n.arg1, n.arg2.arg2)
      n.bin_op = op_in
      n.arg1 = o1
      n.arg2 = o2
    end
  }
}

function M.find_transform_sites(graph, rule_name)
  local sites = {}

  local function try_rule(rule_name, node)
    local rule = assert(TransformRules[rule_name], 'unknown rule' .. rule_name)
    local m = rule.match(node)
    if m then
      table.insert(sites, { rule = rule_name, place = m})
    end
  end

  local function detect_possibility(node)
    if rule_name then -- try specific rule only
      try_rule(rule_name, node)
    else -- no candidate given, try all
      for name, _ in pairs(TransformRules) do
        try_rule(name,node)
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
