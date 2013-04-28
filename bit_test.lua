--require 'luabit/bit'

require 'bit'

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

-- t1 = bit.sub(bit.tobits(3), 3, 0)
-- t2 = bit.sub(bit.tobits(0xa), 3, 0)
-- t3 = bit.tobits(4294967296 - 3)
-- t4 = bit.tobits(4294967296 - 0xa)
-- dump_bits(t1)
-- dump_bits(bit.bnot(t1))

-- dump_bits(t2)
-- dump_bits(bit.bnot(t2))

-- dump_bits(t3)
-- dump_bits(t4)

-- dump_bits(bit.tobits(-1))
-- dump_bits(bit.tobits(-2))
-- dump_bits(bit.tobits(-2147483648-1))


-- 2's complement
-- assume 32 bits data width, 2^32 - n + 1
function twos_comp(n)
   return (n<0) and (4294967296+n) or n
end

function cflag_by_add(n1, n2)
   n1, n2 = twos_comp(n1), twos_comp(n2)   
   return n1+n2 > 4294967295
end

function cflag_by_sub(n1, n2)
   n1, n2 = twos_comp(n1), twos_comp(n2)   
   return n1 < n2
end


function test_carry_add(n1, n2)
   dump_bits(bit.tobits(n1))
   dump_bits(bit.tobits(n2))
   dump_bits(bit.tobits(n1+n2))
   print(cflag_by_add(n1, n2))
end

function test_carry_sub(n1, n2)
   dump_bits(bit.tobits(n1))
   dump_bits(bit.tobits(n2))
   dump_bits(bit.tobits(n1-n2))
   print(cflag_by_sub(n1, n2))
end


local function sign_bit_of(n)
   return bit.tobits(n)[31]
end


local function vflag_by_add(n1, n2)
   local s1 = sign_bit_of(n1)
   local s2 = sign_bit_of(n2) 
   local s3 = sign_bit_of(n1+n2)
   return s1==s2 and s1~=s3
end

local function vflag_by_sub(n1, n2)
   local s1 = sign_bit_of(n1)
   local s2 = sign_bit_of(n2)
   local s3 = sign_bit_of(n1-n2)
   return s1~=s2 and s1~=s3
end

function test_over_add(n1, n2)
   print(n1, '+', n2)
   dump_bits(bit.tobits(n1))
   dump_bits(bit.tobits(n2))
   dump_bits(bit.tobits(n1+n2))
   print(vflag_by_add(n1, n2))
end

function test_over_sub(n1, n2)
   print(n1, '-', n2)
   dump_bits(bit.tobits(n1))
   dump_bits(bit.tobits(n2))
   dump_bits(bit.tobits(n1-n2))
   print(vflag_by_sub(n1, n2))
end



-- test_over_add(-1, 1)
-- test_over_add(2147483647, 1)
-- test_over_add(-2147483648, 1)
-- test_over_sub(-2147483648, 1)
-- test_over_sub(0, 1)
-- test_over_sub(-2, -1)


local function f1()
   print(1)
end

local function f2()
   print(2)
end


ft = {
   [1] = f1,
   [2] = f2,
}

function test_para(a, b, c)
   print (type(a))
   print (type(b))
   print (type(c))
end

-- test_para(nil, 1, 2)
-- test_para(nil, '1', nil)

ft[1]()
ft[2]()



-- dump_bits(bit.bor(t1, t2))
-- dump_bits(bit.band(t1, t2))
-- dump_bits(bit.bxor(t1, t2))


-- t3 = bit.append(t1, t2)
-- t4 = bit.extend_logic(t3)
-- print (t1.size, t2.size, t3.size, t4.size)
-- dump_bits(t4)

