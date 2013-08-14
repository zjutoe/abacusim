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

      typedef uint32_t abi_ulong __attribute__((aligned(4)));
      
      typedef struct CPUMIPSState {
	 abi_ulong gpr[32];
	 uint32_t tls_value;
      } CPUMIPSState;

      uint32_t do_syscall_lua(void* env, abi_ulong arg5, abi_ulong arg6, abi_ulong arg7, abi_ulong arg8);
]]

local sys = ffi.load('syscall')

-- function _m.sys_getegid()
--    return sys.do_getegid()
-- end

function _m.do_syscall(R, mem)
   local sp = R:get(R.sp)
   local arg5 = mem:rd(sp + 16)
   local arg6 = mem:rd(sp + 20)
   local arg7 = mem:rd(sp + 24)
   local arg8 = mem:rd(sp + 28)
   local env = ffi.new("struct CPUMIPSState", R)

   local ret = sys.do_syscall_lua(env, arg5, arg6, arg7, arg8)
   
   R:set(2, ret)		-- R[2] is the return value
end

-- print(sys_getegid())

