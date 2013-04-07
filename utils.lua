local function tobits(v)
   -- TODO assert(v>=0)

   -- v <= 2^32-1
   if v > 4294967295 then
      return nil
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

local function sub_tonum(t, i, j)
   if i<j or i>31 or j<0 then
      return nil
   end

   local n = 0
   for k=i, j, -1 do
      n = n + n + t[k]
   end

   return n
end

local function bits_v(v, i, j)
   return sub_tonum(tobits(v), i, j)
end


local function sub(t, m, n)
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

local function concate(t1, t2)
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

local function extend_logic(t)
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

local function tonum(t)
   local v = 0
   for i=t.size-1, 0 do
      v = v + v + t[i]
   end
   return v
end

local function bits(v, i, j)
   local t = sub(tobits(v), i, j)
   return tonum(t)
end



local function rotate_left(t, n)
   local t1 = sub(t, 31-n, 0)
   local t2 = sub(t, 31, 32-n)
   return concate(t1, t2)
end

local function rotate_right(t, n)
   local t1 = sub(t, n-1, 0)
   local t2 = sub(t, 31, n)
   return concate(t1, t2)
end

local function shift_logic_left(t, n)
   local t1 = sub(t, 31-n, 0)
   local t2 = {}
   for i=0, n-1 do
      t2[i] = 0
   end
   t2.size = n
   return concate(t1, t2)
end

local function shift_logic_right(t, n)
   local t1 = sub(t, 31, n)
   local t2 = {}
   for i=0, n-1 do
      t2[i] = 0
   end
   t2.size = n
   return concate(t2, t1)
end


local function rotate_left_v(v, n)
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

local function rotate_right_v(v, n)
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

local function logical_left_shift_v(v, n)
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

local function logical_right_shift_v(v, n)
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


bit = {
tobits = tobits,
tonum = tonum,
bits = bits,
rol = rotate_left,
ror = rotate_right,
sll = shift_logic_left,
slr = shift_logic_right,
sub = sub,
concate = concate,
extend_logic = extend_logic,

-- bits = bits_v,
-- rleft = rotate_left_v,
-- rright = rotate_right_v,
-- sll = logical_left_shift_v,
-- slr = logical_right_shift_v,
}