--require 'luabit/bit'

require 'utils'

-- function tobits(v)
--    -- TODO assert(v>=0)
--    -- v <= 2^32-1
--    if v > 4294967295 then
--       return nil
--    end

--    local t = {}
--    local i = 0
   
--    while v > 0 do
--       local remain = v % 16
--       v = (v - remain) / 16
      
--       if remain == 0 then	 
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,0,0	
--       elseif remain == 1 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,0,1	
--       elseif remain == 2 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,1,0	
--       elseif remain == 3 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,1,1	
--       elseif remain == 4 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,0,0	
--       elseif remain == 5 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,0,1	
--       elseif remain == 6 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,1,0	
--       elseif remain == 7 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,1,1	
--       elseif remain == 8 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,0,0	
--       elseif remain == 9 then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,0,1	
--       elseif remain == 0xa then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,1,0	
--       elseif remain == 0xb then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,1,1	
--       elseif remain == 0xc then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,0,0	
--       elseif remain == 0xd then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,0,1	
--       elseif remain == 0xe then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,1,0	
--       elseif remain == 0xf then
-- 	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,1,1	
--       end

--       i = i + 4
--    end
   
--    return t
-- end

-- function tonum(t, i, j)
--    if i<j or i>31 or j<0 then
--       return nil
--    end

--    local n = 0
--    for k=i, j, -1 do
--       n = n + n + t[k]
--    end

--    return n
-- end

t = bit.tobits(0xaa00aa)

-- for i=31, 3, -4 do
--    print (t[i], t[i-1], t[i-2], t[i-3])   
-- end

-- n = bit.tonum(t, 23, 16)
-- print (string.format("t[23:16]=%x", n))

-- print (string.format("0xffaa00bc[27:20]=%x", bit.seg(0xffaa00bc, 27, 20)))

function dump_bits(t) 
   for i=31, 0, -1 do
      if t[i] then 
	 io.write(t[i])
      else
	 io.write(0)
      end
   end
   print('')
end

--t = bit.rotate_right(0xaf00000d, 3)
--dump_bits(bit.tobits(t))

t1 = bit.sub(bit.tobits(3), 3, 0)
t2 = bit.sub(bit.tobits(0xa), 3, 0)
t3 = bit.tobits(4294967296 - 3)
t4 = bit.tobits(4294967296 - 0xa)
dump_bits(t1)
dump_bits(bit.bnot(t1))

dump_bits(t2)
dump_bits(bit.bnot(t2))

dump_bits(t3)
dump_bits(t4)

-- dump_bits(bit.bor(t1, t2))
-- dump_bits(bit.band(t1, t2))
-- dump_bits(bit.bxor(t1, t2))


-- t3 = bit.append(t1, t2)
-- t4 = bit.extend_logic(t3)
-- print (t1.size, t2.size, t3.size, t4.size)
-- dump_bits(t4)

