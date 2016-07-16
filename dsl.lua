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

function Var(v)
  local o = {}
  o.var = v
  o.type = 'var'
  setmetatable(o, node_mt)
  return o
end

function Num(n)
  local o = {}
  o.num = n
  o.type = 'num'
  setmetatable(o, node_mt)
  return o
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
  return o
end

return M
