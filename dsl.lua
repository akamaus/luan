-- For use of the global environment from this scope.
local strict = require "std.strict"
local _ENV = strict (_G)

local Plus = '+'
local Mul = '*'
local Lt = '<'

local OpTable = {
  [Plus] = { f = function(a,b) return a+b end,
             cost = 1
           },
  [Mul] = { f = function(a,b) return a*b end,
            cost = 10
          }
}

local BinOp

local node_mt = {
  __add = function(a,b)
    return BinOp(Plus,a,b)
  end,
  __mul = function(a,b)
    return BinOp(Mul,a,b)
  end,
  __lt = function(a,b)
    return BinOp(Lt, a,b)
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

-- walking graph

function walk_graph(g, callback)
  local unvisited = { g }
  local known = {}

  local function enqueue_if_new(n)
    assert(type(n) == 'table')
    if known[n] then return end
    table.insert(unvisited, n)
    known[n] = true
  end

  repeat
    local n = table.remove(unvisited)
    assert(type(n) == 'table' and n.type)
    if n.type == 'bin_op' then
      enqueue_if_new(n.arg1)
      enqueue_if_new(n.arg2)
    end
    callback(n)
  until #unvisited == 0
end

-- rendering

function render_graph(graph, file)
   local f = io.open(file, "wb")
   f:write("digraph expr {\n")

   local node_indices = {}
   local last_idx = 0

   local function reify_node(n)
     assert(type(n) == 'table')

     if node_indices[n] then
       return node_indices[n]
     else
       last_idx = last_idx + 1
       node_indices[n] = last_idx
       return last_idx
     end
   end

   local function render_node(n)
     assert(n.type)
     if n.type == 'num' then
       f:write(string.format('  v%d [label="%d" color="green"];\n', reify_node(n), n.num))
     elseif n.type == 'var' then
       f:write(string.format('  v%d [label="%s" color="blue"];\n', reify_node(n), n.var))
     elseif n.type == 'bin_op' then
       f:write(string.format('  v%d [label="%s"] [shape="box"];\n', reify_node(n), n.bin_op))
     else error("unknown type " .. n.type)
     end
   end

   local function render_deps(n)
     if n.type ~= 'bin_op' then return end
     f:write(string.format('  v%d -> v%d;\n', reify_node(n), reify_node(n.arg1)))
     f:write(string.format('  v%d -> v%d;\n', reify_node(n), reify_node(n.arg2)))
   end

   walk_graph(graph, render_node)
   walk_graph(graph, render_deps)

   f:write("}")
   f:close()
end

function eval_node(node, env)
  local val, cost
  if node.type == 'num' then
    val,cost = node.num, 0
  elseif node.type == 'var' then
    val = assert(env[node.var], 'unknown variable ' .. node.var)
    cost = 0
  elseif node.type == 'bin_op' then
    local op = assert(OpTable[node.bin_op], 'unknown op')
    local arg1,cost1 = eval_node(node.arg1, env)
    local arg2,cost2 = eval_node(node.arg2, env)

    val = op.f(arg1, arg2)
    cost = op.cost + cost1 + cost2
  else
    error('cant evaluate ' .. node.type)
  end

  return val, cost
end


