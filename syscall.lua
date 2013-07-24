local ffi = require 'ffi'

ffi.cdef[[

    uint32_t do_getegid();

]]

local sys = ffi.load('syscall')

function sys_getegid()
   return sys.do_getegid()
end

print(sys_getegid())

