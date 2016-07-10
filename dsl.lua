


local Plus = '+'
local Mul = '*'
local Lt = '<'

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

local function Var(v)
  local o = {}
  o.var = v
  o.type = 'var'
  setmetatable(o, node_mt)
end

local function BinOp(op, a,b)
  local o = {}
  o.op = op
  o.arg1 = a
  o.arg2 = b
  o.type = 'bin_op'
  setmetatable(o, node_mt)
end

-- walking graph

local function walk_graph(g, callback)
  local unvisited = { g }
  local visited = {}

  local function enqueue_if_new(n)
    if type(n) == 'table' then
      if visited[n] then return end
      table.insert(unvisited, n)
      visited[n] = true
    end
  end

  repeat
    n = table.remove(unvisited)
    if type(n) == 'number' then callback(n)
    elseif type(n) == 'table' then
      if n.type == 'bin_op' then
        enqueue_if_new(n.arg1)
        enqueue_if_new(n.arg2)
      end
      callback(n)
    else assert('unknown node type' .. type(n))
  until #unvisited == 0
end

-- rendering


function render_graph(graph, file)
   local f = io.open(file, "wb")
   f:write("expr {\n")

   local node_indices = {}
   local last_idx = 0

   local function render_num(n)
     assert(type(n) == 'number')

     local idx = last_idx
     last_idx = last_idx + 1
     f:write(string.format('  v%d [label="%d"]\n', idx, n))
     return idx
   end

   local function reify_node(n)
     if type(n) ~= 'table' then
       return nil
     end
     if node_indices[n] then
       return node_indices[n]
     else
       last_idx = last_idx + 1
       node_indices[n] = last_idx
       return last_idx
     end
   end

   walk_graph(graph, reify_node)


   local function render_node(n)
     if type(n) == 'table' then
       if n.type == 'var' then
         f:write(string.format('  v%d [label="%s"]', reify_node[n], n.var))
       elseif n.type == '
   
   local function render_branch(b)
      f:write(string.format('  v%d [label="%s\np=%.2f\ns=%d"]\n', reify_node(b), b.criterion:Stringify(), b.prec, b.size))
      f:write(string.format('  v%d -> v%d [color=red];\n', reify_node(b), reify_node(b.neg)))
      f:write(string.format('  v%d -> v%d [color=blue];\n\n', reify_node(b), reify_node(b.pos)))
   end

   local function render_leaf(l)
      local color
      if l.answer then
         color = "green"
      else
         color = "brown"
      end
      f:write(string.format('  v%d [label="p=%.2f\ns=%d"] [shape=box] [color=%s]\n', reify_node(l), l.prec, l.size, color))
   end

   walk_tree(tree, render_branch, render_leaf)

   f:write("}")
   f:close()
end



--testing

a = Var "a"
b = Var "b"

res = 3 * a + b + 5 * a + 10 * b

