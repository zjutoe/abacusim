local pairs = pairs

module(...)

local _bit = {}

function init()
   local m = {}
   for k, v in pairs(_bit) do
      m[k] = v
   end
   
   m.rr = m.rotate_right
   m.rl = m.rotate_left
   m.sll = m.shift_left_logic
   m.srl = m.shift_right_logic
   m.sra = m.shift_right_arithmetic   

   return m
end

function _bit.tobits(v)
   if not v then return nil end

   if v < 0 then 
      v = 0x100000000 + v
   end

   local t = {}
   local i = 0
   
   while v > 0 do
      local remain = v % 16
      v = (v - remain) / 16
      
      if remain == 0 then	 
	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,0,0	
      elseif remain == 1 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,0,1	
      elseif remain == 2 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,1,0	
      elseif remain == 3 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,0,1,1	
      elseif remain == 4 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,0,0	
      elseif remain == 5 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,0,1	
      elseif remain == 6 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,1,0	
      elseif remain == 7 then
	 t[i+3],t[i+2],t[i+1],t[i] = 0,1,1,1	
      elseif remain == 8 then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,0,0	
      elseif remain == 9 then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,0,1	
      elseif remain == 0xa then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,1,0	
      elseif remain == 0xb then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,0,1,1	
      elseif remain == 0xc then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,0,0	
      elseif remain == 0xd then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,0,1	
      elseif remain == 0xe then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,1,0	
      elseif remain == 0xf then
	 t[i+3],t[i+2],t[i+1],t[i] = 1,1,1,1	
      end

      i = i + 4
   end

   for i=i, 31 do
      t[i] = 0
   end

   t.size = 32
   
   return t
end


function _bit.tostr(t)
   local s = {}
   for i=31, 0, -1 do
      if t[i] then 
	 s[32-i] = (t[i]==1) and '1' or '0'
      else
	 s[32-i] = '0'
      end
   end
   return table.concat(s)
end


function _bit.tonum(t)
   local v = 0
   for i=t.size-1, 0, -1 do
      v = v + v + t[i]
   end
   return v
end


function _bit.sub_tonum(t, i, j)
   if i<j or i>31 or j<0 then
      return nil
   end

   local n = 0
   for k=i, j, -1 do
      n = n + n + t[k]
   end

   return n
end

function _bit.sub_tonum_se(t, i, j)
   if i<j or i>31 or j<0 then
      return nil
   end

   local n = 0
   if t[i] == 1 then
      for k=i, j, -1 do
	 n = n + n + 1 - t[k]	-- ~t[k], i.e. (t[k]==1 and 0 or 1)
      end
      n = -(n + 1)
   else
      for k=i, j, -1 do
	 n = n + n + t[k]
      end
   end

   return n
end


function _bit.sub(t, m, n)
   if m<n or m>31 or n<0 then return nil end

   local t2 = {}
   local i = 0
   for k=n, m do
      t2[i] = t[k]
      i = i +1
   end

   t2.size = i

   return t2
end

function _bit.concate(t1, t2)
   if t1 == nil then
      return t2 
   elseif t2 == nil then
      return t1
   end
   
   if t1.size + t2.size > 32 then return nil end

   local t3 = {}
   local k = t1.size-1
   for i=t1.size+t2.size-1, t1.size, -1 do
      t3[i] = t1[k]
      k = k -1
   end
   for i=t2.size-1, 0, -1 do
      t3[i] = t2[i]
   end   

   t3.size = t1.size + t2.size

   return t3
end

function _bit.extend_logic(t)
   local t2 = {}
   
   for i=0, t.size-1 do
      t2[i] = t[i]
   end
   for i=t.size, 31 do
      t2[i] = 0
   end

   t2.size = 32

   return t2   
end

function _bit.bits(v, i, j)
   local t = _bit.sub(tobits(v), i, j)
   return tonum(t)
end



function _bit.rotate_left(t, n)
   local sub = _bit.sub
   local t1 = sub(t, 31-n, 0)
   local t2 = sub(t, 31, 32-n)
   return concate(t1, t2)
end

function _bit.rotate_right(t, n)
   local sub = _bit.sub
   local t1 = sub(t, n-1, 0)
   local t2 = sub(t, 31, n)
   return concate(t1, t2)
end

function _bit.shift_left_logic(t, n)
   local t1 = _bit.sub(t, 31-n, 0)
   local t2 = {}
   for i=0, n-1 do
      t2[i] = 0
   end
   t2.size = n
   return _bit.concate(t1, t2)
end

function _bit.shift_right_logic(t, n)
   local t1 = _bit.sub(t, 31, n)
   local t2 = {}
   for i=0, n-1 do
      t2[i] = 0
   end
   t2.size = n
   return concate(t2, t1)
end

function _bit.band(t1, t2)
   if t1.size<0 or t2.size<0 then return nil end

   if t1.size < t2.size then
      t1, t2 = t2, t1
   end

   local t3 = {}
   for i=0, t2.size-1 do
      t3[i] = (t1[i]==1 and t2[i]==1) and 1 or 0
   end
   t3.size = t2.size

   return t3
end


function _bit.bor(t1, t2)
   if t1.size<0 or t2.size<0 then return nil end

   if t1.size < t2.size then
      t1, t2 = t2, t1
   end

   local t3 = {}
   for i=0, t2.size-1 do
      t3[i] = (t1[i]==0 and t2[i]==0) and 0 or 1
   end
   for i=t2.size, t1.size-1 do
      t3[i] = t1[i]
   end
   t3.size = t1.size

   return t3
end


function _bit.bxor(t1, t2)   
   if t1.size<0 or t2.size<0 then return nil end

   if t1.size < t2.size then
      t1, t2 = t2, t1
   end

   local t3 = {}
   for i=0, t2.size-1 do
      t3[i] = (t1[i]==t2[i]) and 0 or 1
   end
   for i=t2.size, t1.size-1 do
      t3[i] = (t1[i]==0) and 0 or 1
   end
   t3.size = t1.size

   return t3
end


function _bit.bnot(t)
   if t.size<0 then return nil end

   local t2 = {}
   for i=0, t.size-1 do
      t2[i] = (t[i]==1) and 0 or 1
   end
   for i=t.size, 31 do
      t2[i] = 1
   end

   t2.size = t.size

   return t2
end




function _bit.shift_right_arithmetic(t, n)
   local s = t[31]
   local t1 = sub(t, 31, n)
   local t2 = {}
   for i=0, n-1 do
      t2[i] = s
   end
   t2.size = n
   return concate(t2, t1)
end

function _bit.bits_v(v, i, j)
   return sub_tonum(tobits(v), i, j)
end

function _bit.rotate_left_v(v, n)
   if n>32 or n<0 then return nil end

   local b = tobits(v)
   local t = {}

   local j = 31
   for i=31-n, 0, -1 do
      t[j] = b[i]
      j = j - 1
   end
   for i=31, 32-n, -1 do
      t[j] = b[i]
      j = j - 1
   end

   return tonumber(t)
end

function _bit.rotate_right_v(v, n)
   if n>32 or n<0 then return nil end

   local b = tobits(v)
   local t = {}

   local j = 0
   for i=n, 31 do
      t[j] = b[i]
      j = j + 1
   end
   for i=0, n-1 do
      t[j] = b[i]
      j = j + 1
   end

   return tonumber(t)
end

function _bit.logical_left_shift_v(v, n)
   if n>32 or n<0 then return nil end
   
   local b = tobits(v)
   local t = {}

   local j = 31
   for i=31-n, 0, -1 do
      t[j] = b[i]
      j = j - 1
   end
   for i=31, 32-n, -1 do
      t[j] = 0
      j = j -1
   end      

   return tonumber(t)
end

function _bit.logical_right_shift_v(v, n)
   if n>32 or n<0 then return nil end

   local b = tobits(v)
   local t = {}

   local j = 0
   for i=n, 31 do
      t[j] = b[i]
      j = j + 1
   end
   for i=0, n-1 do
      t[j] = 0
      j = j + 1
   end

   return tonumber(t)
end


-- bit = {
--    tobits = tobits,
--    tonum = tonum,
--    sub_tonum = sub_tonum,
--    sub_tonum_se = sub_tonum_se,
--    tostr = tostr,
--    band = band,
--    bor = bor,
--    bxor = bxor,
--    bnot = bnot,
--    bits = bits,
--    rol = rotate_left,
--    ror = rotate_right,
--    sll = shift_left_logic,
--    srl = shift_right_logic,
--    sra = shift_right_arithmetic,
--    sub = sub,
--    concate = concate,
--    extend_logic = extend_logic,

-- -- bits = bits_v,
-- -- rleft = rotate_left_v,
-- -- rright = rotate_right_v,
-- -- sll = logical_left_shift_v,
-- -- slr = logical_right_shift_v,
-- }
