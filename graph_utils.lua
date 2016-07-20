-- For use of the global environment from this scope.
local strict = require "std.strict"
local _ENV = strict (_G)

-- walking graph

local D = require 'dsl'

local M = {}

function M.clone_graph(g)
  local nodes = {}

  local function copier(n)
    nodes[n] = clone_table(n)
  end

  local function linker(n)
    local cn = assert(nodes[n])
    if cn.type == 'bin_op' then
      cn.arg1 = nodes[cn.arg1]
      cn.arg2 = nodes[cn.arg2]
    end
  end

  M.walk_graph(g, copier)
  M.walk_graph(g, linker)

  return assert(nodes[g])
end

function M.walk_path(g, path)
  for _,d in ipairs(path) do
    if d == 'L' then
      g = g.arg1
    elseif d == 'R' then
      g = g.arg2
    else error "strange path"
    end
  end
  return g
end

function M.walk_graph(g, callback)
  local unvisited = { { node = g, path = {} } }
  local known = {}

  local function enqueue_if_new(n, path)
    assert(type(n) == 'table', 'strange node type' .. type(n))
    if known[n] then return end
    table.insert(unvisited, { node = n, path = path } )
    known[n] = true
  end

  repeat
    local n = table.remove(unvisited)
    local node = n.node
    assert(type(n) == 'table' and n.node and n.node.type)
    if node.type == 'bin_op' then
      local path_r = clone_table(n.path)
      table.insert(path_r,'R')
      enqueue_if_new(node.arg2, path_r)
      local path_l = clone_table(n.path)
      table.insert(path_l,'L')
      enqueue_if_new(node.arg1, path_l)
    end
    callback(n.node, n.path)
  until #unvisited == 0
end

-- rendering

function M.render_graph(graph, file)
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
     f:write(string.format('  v%d -> v%d [label="arg2"];\n', reify_node(n), reify_node(n.arg2)))
     f:write(string.format('  v%d -> v%d [label="arg1"];\n', reify_node(n), reify_node(n.arg1)))
   end

   M.walk_graph(graph, render_node)
   M.walk_graph(graph, render_deps)

   f:write("}")
   f:close()
end

function M.draw_graph(graph)
  local tmp = os.tmpname("graph")
  M.render_graph(graph, tmp)
  os.execute('./render_graph.sh ' .. tmp)
  os.remove(tmp)
end

function M.eval_graph(node, env)
  local val, cost
  if node.type == 'num' then
    val,cost = node.num, 0
  elseif node.type == 'var' then
    val = assert(env[node.var], 'unknown variable ' .. node.var)
    cost = 0
  elseif node.type == 'bin_op' then
    local op = assert(D.OpTable[node.bin_op], 'unknown op')
    local arg1,cost1 = M.eval_graph(node.arg1, env)
    local arg2,cost2 = M.eval_graph(node.arg2, env)

    val = op.f(arg1, arg2)
    cost = op.cost + cost1 + cost2
  else
    error('cant evaluate ' .. node.type)
  end

  return val, cost
end

return M
