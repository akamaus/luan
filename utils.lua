function clone_table(t)
  local nt = {}
  for i,v in pairs(t) do
    nt[i] = v
  end
  setmetatable(nt, getmetatable(t))
  return nt
end

function print_table(t)
  print('{')
  for i,v in pairs(t) do
    print(i,v)
  end
  print('}')
end
