-- For use of the global environment from this scope.
local strict = require "std.strict"
local _ENV = strict (_G)

T = require 'transform'
G = require 'graph_utils'

require 'utils'
local D = require 'dsl'

local B = {}

function B.enum_breadth_first(graph)
  local seen_graphs = {}
  local front = { graph }
  local new_front = {}

  local walked = 0
  local breeded = 0
  repeat
    walked = walked + #front
    print("front", #front, 'nodes:', #D.get_node_sea())
    while #front > 0 do
      local g = table.remove(front)
      local sites = T.find_transform_sites(g)
      for _,trans in ipairs(sites) do
        breeded = breeded + 1
        local g2 = G.clone_graph(g)
        T.apply_transform(g2, trans)
        local g_str = tostring(g2)
        if not seen_graphs[g_str] then
          table.insert(new_front, g2)
          seen_graphs[g_str] = g2
        end
      end
    end
    front,new_front = new_front,front
  until #front == 0

  print('num fronts', walked, breeded)

  local ret_graphs = {}
  for s,g in pairs(seen_graphs) do
    table.insert(ret_graphs, g)
  end

  return ret_graphs
end

return B
