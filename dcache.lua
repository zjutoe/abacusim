dcache = {}

function dcache.rd(self, addr)
   if self[math.floor(addr / 4) + 1] == nil then print ('dcache miss') end
   return self[math.floor(addr / 4) + 1]
end

function dcache.wr(self, addr, v)
   self[math.floor(addr / 4) + 1] = v
end

