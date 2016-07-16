local strict = require "std.strict"
local _ENV = strict (_G)

package.path=package.path .. ';?.lua'
require 'dsl'

local M = {}

local function cmp_nodes(t1,t2)
  assert(t1.type)
  assert(t2.type)
  if t1.type ~= t2.type then return false end

  if t1.type == 'num' then return t1.num == t2.num
  elseif t1.type == 'var' then return t1.var == t2.var
  elseif t1.type == 'bin_op' then return t1.bin_op == t2.bin_op and cmp_nodes(t1.arg1, t2.arg1) and cmp_nodes(t1.arg2, t2.arg2)
  else error "cant compare"
  end
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
        return true
      end
    end,
    apply = function(n)
      n.arg1, n.arg2 = n.arg2, n.arg1
    end
  },
  assoc_l = {
    match = function(n)
      if n.type == 'bin_op' and AssocOps[n.bin_op] and n.bin_op == n.arg1.bin_op then
        return true
      end
    end,
    apply = function(n)
      local n_l = n.arg1
      local n_r = n
      local nl = clone_table(n_l)
      n_r.arg1 = nl
      rotate_nodes(nl, n_r)
    end
  },
  assoc_r = {
    match = function(n)
      if n.type == 'bin_op' and AssocOps[n.bin_op] and n.bin_op == n.arg2.bin_op then
        return true
      end
    end,
    apply = function(n)
      local n_l = n
      local n_r = n.arg2
      local nr = clone_table(n_r)
      n_l.arg2 = nr

      rotate_nodes(n_l, nr)
    end
  },
  distrib = {
    match = function(n)
      if n.type == 'bin_op' and n.arg2.type == 'bin_op' then
        for _,p in ipairs(DistrOpPairs) do
          if p[1] == n.bin_op and p[2] == n.arg2.bin_op then
            return true
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
  },
  factor = {
    match = function(n)
      if n.type == 'bin_op' and n.arg1.type == 'bin_op' and n.arg2.type == 'bin_op' then
        for _,p in ipairs(DistrOpPairs) do
          if p[2] == n.bin_op and p[1] == n.arg1.bin_op and p[1] == n.arg2.bin_op and cmp_nodes(n.arg1.arg1, n.arg2.arg1) then
            return true
          end
        end
      end
    end,
    apply = function(n)
      local op_out = n.bin_op
      local op_in = n.arg1.bin_op
      local o = BinOp(op_out, n.arg1.arg2, n.arg2.arg2)
      n.bin_op = op_in
      n.arg1 = n.arg1.arg1
      n.arg2 = o
    end
  }
}

function M.find_transform_sites(graph, rule_name)
  local sites = {}

  local function try_rule(rule_name, node, path)
    local rule = assert(TransformRules[rule_name], 'unknown rule' .. rule_name)
    if rule.match(node) then
      table.insert(sites, { rule = rule_name, path = path})
    end
  end

  local function detect_possibility(node, path)
    if rule_name then -- try specific rule only
      try_rule(rule_name, node, path)
    else -- no candidate given, try all
      for name, _ in pairs(TransformRules) do
        try_rule(name,node,path)
      end
    end
  end

  walk_graph(graph, detect_possibility)

  return sites
end

function M.apply_transform(graph, site)
  assert(graph.type)
  assert(type(site.path) == 'table')
  local r = assert(TransformRules[site.rule], 'rule not found')
  local g = walk_path(graph, site.path)
  r.apply(g)
end

return M
