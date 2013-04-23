require "utils"

local bit = bit

module(...)


-- TODO refer to A5.2.1
-- ld_st_reg_offset,
-- ld_st_mult,

-- load store immediate offset
function do_ld_st_imm_offset(inst, dcache, R)
   local Rn  = bit.sub_tonum(inst, 19, 16)
   local Rd  = bit.sub_tonum(inst, 15, 12)
   local imm = bit.sub_tonum(inst, 7, 0)

   
end
