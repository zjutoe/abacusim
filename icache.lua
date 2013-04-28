local math = math
local pairs = pairs

module(...)

local cache = {
   [0] = 0xe52db004, 	-- push	{fp}		; (str fp, [sp, #-4]!)
   0xe28db000,		-- add	fp, sp, #0
   0xe24dd00c,		-- sub	sp, sp, #12
   0xe3a03000,		-- mov	r3, #0
   0xe50b300c,		-- str	r3, [fp, #-12]
   0xe3a03000,		-- mov	r3, #0
   0xe50b3008,		-- str	r3, [fp, #-8]
   0xea000006,		-- b	3c <data_process+0x3c>
   0xe51b200c,		-- ldr	r2, [fp, #-12]
   0xe51b3008,		-- ldr	r3, [fp, #-8]
   0xe0823003,		-- add	r3, r2, r3
   0xe50b300c,		-- str	r3, [fp, #-12]
   0xe51b3008,		-- ldr	r3, [fp, #-8]
   0xe2833001,		-- add	r3, r3, #1
   0xe50b3008,		-- str	r3, [fp, #-8]
   0xe51b3008,		-- ldr	r3, [fp, #-8]
   0xe3530063,		-- cmp	r3, #99	; 0x63
   0xdafffff5,		-- ble	20 <data_process+0x20>
   0xe51b300c,		-- ldr	r3, [fp, #-12]
   0xe1a00003,		-- mov	r0, r3
   0xe28bd000,		-- add	sp, fp, #0
   0xe8bd0800,		-- pop	{fp}
   0xe12fff1e,		-- bx	lr
}

function init()
   local c = {}
   for k, v in pairs(cache) do
      c[k] = v
   end
   return c
end

function cache.rd(self, addr)
   -- if self[math.floor(addr / 4) + 1] == nil then print ('icache miss') end
   return self[math.floor(addr / 4)]
end


-- debug only
-- function cache.dump_code(self)
--    for i, v in ipairs(self) do
--       if i % 4 == 1 then
-- 	 print('   7   6   5   4   3   2   1   0')
--       end
--       print(bit.tostr(bit.tobits(v)), string.format("%x:%x", v, (i-1)*4))
--    end
-- end

-- icache:dump_code()
