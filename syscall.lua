local pairs = pairs
local ffi = require 'ffi'

module(...)

local _m = {}

function init()
   local m = {}
   for k, v in pairs(_m) do
      m[k] = v
   end
   
   return m
end



ffi.cdef[[

    uint32_t do_getegid();

]]

local sys = ffi.load('syscall')

function _m.sys_getegid()
   return sys.do_getegid()
end

function _m.do_syscall(R)
   local code = R:get(R.v0)
   local ret
   if code == 4045 then		-- 0xfcd
      ret = sys.do_getegid()
   else
      return -1			-- raise exception in the caller
   end

   R:set(11, ret)		-- R[11] is the return value
   return 0
end

-- print(sys_getegid())

