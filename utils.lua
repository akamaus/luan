function clone_table(t)
  local nt = {}
  for i,v in pairs(t) do
    nt[i] = v
  end
  setmetatable(nt, getmetatable(t))
  return nt
end
