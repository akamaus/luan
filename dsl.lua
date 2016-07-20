-- For use of the global environment from this scope.
local strict = require "std.strict"
local _ENV = strict (_G)

require 'utils'

local M = {}

Plus = '+'
Mul = '*'
local Lt = '<'

M.AssocOps = { [Plus] = true, [Mul] = true }
M.DistrOpPairs = { { Mul, Plus } }

M.OpTable = {
  [Plus] = { f = function(a,b) return a+b end,
             cost = 1
           },
  [Mul] = { f = function(a,b) return a*b end,
            cost = 10
          }
}

BinOp = nil

local node_mt = {
  __add = function(a,b)
    return BinOp(Plus,a,b)
  end,
  __mul = function(a,b)
    return BinOp(Mul,a,b)
  end,
  __lt = function(a,b)
    return BinOp(Lt, a,b)
  end,
  __tostring = function(n)
    if n.type == 'bin_op' then
      return tostring( '(' .. tostring(n.arg1) .. n.bin_op .. tostring(n.arg2) .. ')')
    elseif n.type == 'num' then return tostring(n.num)
    elseif n.type == 'var' then return tostring(n.var)
    else error "cant print"
    end
  end
}

-- This is global node storage
M.NodeSea = {}

function M.cmp_nodes(t1,t2)
  assert(t1.type)
  assert(t2.type)
  if t1.type ~= t2.type then return false end

  if t1.type == 'num' then return t1.num == t2.num
  elseif t1.type == 'var' then return t1.var == t2.var
  elseif t1.type == 'bin_op' then return t1.bin_op == t2.bin_op and M.cmp_nodes(t1.arg1, t2.arg1) and M.cmp_nodes(t1.arg2, t2.arg2)
  else error "cant compare"
  end
end

-- node deduplication
local function reify_node(n)
  local n_str = tostring(n)
  local sn = M.NodeSea[n_str]
  local res
  if sn then
    if M.cmp_nodes(n, sn) then
      print("found " .. n_str)
      res = sn
    else
      print("false find " .. n_str)
      M.NodeSea[n_str] = n
      res = n
    end
  else
    print("new " .. n_str)
    M.NodeSea[n_str] = n
    res = n
  end
  return n
end

-- DSL primitives
function Var(v)
  local o = {}
  o.var = v
  o.type = 'var'
  setmetatable(o, node_mt)
  return reify_node(o)
end

function Num(n)
  local o = {}
  o.num = n
  o.type = 'num'
  setmetatable(o, node_mt)
  return reify_node(o)
end

local function wrapNode(x)
  if type(x) == 'table' then
    assert(x.type)
    return x
  elseif type(x) == 'number' then
    return Num(x)
  else error('unknown type passed to WrapNode: ' .. type(x))
  end
end

BinOp = function(op, a,b)
  local o = {}
  o.bin_op = op
  o.arg1 = wrapNode(a)
  o.arg2 = wrapNode(b)
  o.type = 'bin_op'
  setmetatable(o, node_mt)
  return reify_node(o)
end

return M
