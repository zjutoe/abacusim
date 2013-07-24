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

-- print(sys_getegid())

