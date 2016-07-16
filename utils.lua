function clone_table(t)
  local nt = {}
  for i,v in pairs(t) do
    nt[i] = v
  end
  return nt
end
