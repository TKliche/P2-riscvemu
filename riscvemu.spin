CON
  CMP_UNSIGNED = %100001_110
  CMP_SIGNED   = %110000_110
  
VAR
  long cog
  
PUB start(params)
  cog := cognew(@enter, params) + 1
  return cog

PUB stop
  if (cog > 0)
    cogstop(cog-1)

DAT
		org 0
enter
opcodetab
{00}		jmp	#init		' replaced with load instruction
{01}		jmp	#illegalinstr	' float load
{02}		jmp	#illegalinstr	' custom0
{03}		jmp	#illegalinstr	' fence
{04}		jmp	#immediateop	' math immediate
{05}		jmp	#auipc		' auipc
{06}		jmp	#illegalinstr	' wide math imm
{07}		jmp	#illegalinstr	' ???

{08}		jmp	#storeop	' store
{09}		jmp	#illegalinstr	' float store
{0A}		jmp	#illegalinstr	' custom1
{0B}		jmp	#illegalinstr	' atomics
{0C}		jmp	#regop		' math reg
{0D}		jmp	#lui		' lui
{0E}		jmp	#illegalinstr	' wide math reg
{0F}		jmp	#illegalinstr	' ???

{10}		jmp	#illegalinstr
{11}		jmp	#illegalinstr
{12}		jmp	#illegalinstr
{13}		jmp	#illegalinstr
{14}		jmp	#illegalinstr
{15}		jmp	#illegalinstr
{16}		jmp	#illegalinstr	' custom2
{17}		jmp	#illegalinstr

{18}		jmp	#condbranch	' conditional branch
{19}		jmp	#jalr
{1A}		jmp	#illegalinstr
{1B}		jmp	#jal
{1C}		jmp	#illegalinstr	' system
{1D}		jmp	#illegalinstr
{1E}		jmp	#illegalinstr	' custom3
{1F}		jmp	#illegalinstr

opcode0entry
		jmp	#loadop		'' load
''
'' table for "regular" math operations
'' note that if bits 31..25 of the opcode == 1, we should use
'' the "mul" table instead
'' also note that
mathtab
{0}		jmp	#imp_add	'' add or sub, based on imm field
{1}		jmp	#imp_sll	'' shl
{2}		jmp	#imp_slt	'' set if less than, signed
{3}		jmp	#imp_sltu	'' set if less than, unsigned
{4}		jmp	#imp_xor	'' xori
{5}		jmp	#imp_shr	'' srli or srai, based on imm 
{6}		jmp	#imp_or		'' ori
{7}		jmp	#imp_and	'' andi

multab
{0}		jmp	#imp_mul
{1}		jmp	#illegalinstr	'' mulh, not implemented
{2}		jmp	#illegalinstr	'' mulhsu, not implemented
{3}		jmp	#imp_muluh
{4}		jmp	#imp_div
{5}		jmp	#imp_divu
{6}		jmp	#imp_rem
{7}		jmp	#imp_remu

init
		mov	opcodetab, opcode0entry
		mov	temp, par
		rdlong	cmd_addr, temp
		add	temp, #4
		rdlong	membase, temp
		add	temp, #4
		rdlong	memsize, temp
		add	temp, #4
		rdlong	pc, temp
		add	temp, #4
		add	pc, membase
		mov	x0+2,membase
		add	x0+2,memsize
		rdlong	dbgreg_addr, temp
		jmp	#nexti
		
		''
		'' main instruction decode loop
		''

		'' write back last result from "dest" here
write_and_nexti
		mov	0-0, dest
nexti
		rdlong	opcode, pc
'''		call	#singlestep
		add	pc, #4
		'' check for valid opcodes
		'' the two lower bits must be 11
		'' that means nonzero, even parity on those two bits
		test	opcode, #3 wz,wc
   if_c_or_z	jmp	#illegalinstr
   		mov	temp, opcode
		shr	temp, #7
		and	temp, #$1f wz
		add	temp, #x0
   if_z		mov	temp, #dest	' writes to x0 get ignored
   		movd	write_and_nexti, temp
		mov	temp, opcode
		shr	temp, #2
		and	temp, #$1f
		add	temp, #opcodetab
		jmp	temp		'' jump to instruction decode

		'' come here for illegal instructions
illegalinstr
		mov	newcmd, #2	' signal illegal instruction
		call	#sendcmd
		jmp	#nexti


		''
		'' utility: extract rs1 field from opcode
		'' NOTE: does not actually read value from register
		''
getrs1
		mov	rs1, opcode
		shr	rs1, #15
		and	rs1, #$1f
		add	rs1, #x0
getrs1_ret	ret


getrs2
		mov	rs2, opcode
		sar	rs2, #20
		and	rs2, #$1f
		add	rs2, #x0
getrs2_ret	ret


		'' extract funct3 field
getfunct3
		mov	funct3, opcode
		shr	funct3, #12
		and	funct3, #7
getfunct3_ret
		ret

mulbit		long	(1<<25)

		'' math register operations
regop
		call	#getrs2
		movs	:fetchrs, rs2
		movs	mathtab, #imp_addsub
:fetchrs	mov	rs2, 0-0
		test	opcode, mulbit wz
		mov	desth, #mathtab
	if_nz	mov	desth, #multab
		jmp	#domath
		
		'' math immediate operations
immediateop
		movs	mathtab, #imp_add
		mov	rs2, opcode
		sar	rs2, #20
		mov	desth, #mathtab

		'' generic math routine
		'' enter with rs2 having the decoded value of rs2
		'' (register fetched if applicable)
		'' and with desth containing the table to use
		'' (generic mathtab, or multab)
domath
		call	#getrs1
		movs	:exec1, rs1
		call	#getfunct3
:exec1		mov	dest, 0-0		' load rs1 into dest
		add	funct3, desth		' funct3 pts at instruction

		'' actually execute the decoded instruction here
		jmp	funct3

		'' execute math instructions
		'' for all of these, rs1 is in temp, rs2 has the needed value
		'' result should go in temp
imp_add
		add	dest, rs2
		jmp	#write_and_nexti
imp_addsub
		test	opcode, sra_mask wz
	if_z	add	dest, rs2
	if_nz	sub	dest, rs2
		jmp	#write_and_nexti

imp_sll		shl	dest, rs2
		jmp	#write_and_nexti
		
imp_slt		cmps	dest, rs2 wz,wc
		mov	dest, #0
  if_b		mov	dest, #1
  		jmp	#write_and_nexti
imp_sltu	cmp	dest, rs2 wz,wc
		jmp	#imp_slt+1
imp_xor
		xor	dest, rs2	' FIXME
		jmp	#write_and_nexti
imp_shr
		'' depending on opcode we do sar or shr
		test	opcode, sra_mask wz
	if_z	shr	dest, rs2
	if_nz	sar	dest, rs2
		jmp	#write_and_nexti
		
imp_or		or	dest, rs2
		jmp	#write_and_nexti
		
imp_and		and	dest, rs2
		jmp	#write_and_nexti
		
		'' for sra 31..26 = 16
		'' so 31..24 = 64 = $40
sra_mask	long	$40000000

'' load upper immediate (20 bits)
lui
    		'' extract upper immediate
		mov	dest, opcode
		and	dest, luimask
		jmp	#write_and_nexti
luimask		long	$fffff000


'' load upper 20 bits, added with pc
auipc
		mov	dest, opcode
		and	dest, luimask
		add	dest, pc
		sub	dest, membase
		sub	dest, #4
		jmp	#write_and_nexti

''''''''''''''''''''''''''''''''''''''''''''''''''''
'' jal: jump and link
''''''''''''''''''''''''''''''''''''''''''''''''''''
Jmask		long	$fff00fff
bit11		long	(1<<11)
jal
		mov	temp, opcode	' extract J-immediate
		sar	temp, #20	' sign extend, get some bits in place
		and	temp, Jmask
		andn	opcode, Jmask
		or	temp, opcode	' set bits 19:12
		test	temp, #1 wc	' check old bit 20
		andn	temp, #1 	' clear low bit
		muxc	temp, bit11	' set bit 11
		sub	pc, membase	' and for offset
		mov	dest, pc		' save old pc
		sub	pc, #4		' compensate for pc bump
		add	pc, membase
		add	pc, temp
		jmp	#write_and_nexti

jalr
		mov	rs1, opcode
		sar	opcode, #20	' get offset
		shr	rs1, #15
		and	rs1, #$1f
		add	rs1, #x0
		movs	:jalfetch, rs1
		sub	pc, membase
		mov	dest, pc	' save old pc
:jalfetch	mov	pc, 0-0		' fetch rs1 value
		add	pc, membase
		add	pc, opcode
		jmp	#write_and_nexti
''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' implement load and store
''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'
' table of load instructions
' the I field gives the PASM instruction we have to use to implement
' the load; the S field is 0 for unsigned load, 1 for signed

loadtab
		jmp	#do_rdbyte
		jmp	#do_rdword
		jmp	#do_rdlong
		jmp	#illegalinstr
		
loadop
		call	#getrs1
		movs	:set, rs1
		call	#getfunct3
:set		mov	dest, 0-0	' set dest to value of rs1
		test	funct3, #4 wz	' check for signed/unsigned; Z is set for signed
		and	funct3, #3
		add	funct3, #loadtab
		sar	opcode, #20	' extract immediate
		add	dest, opcode	' add offset
		jmp	funct3

		'' sign bit was set above
do_rdbyte
		add	dest, membase
		rdbyte	dest, dest
	if_z	shl	dest, #24	' if z bit set, sign extend
	if_z	sar	dest, #24
		jmp	#write_and_nexti
do_rdword
		add	dest, membase
		rdword	dest, dest
	if_z	shl	dest, #16	' if z bit set, sign extend
	if_z	sar	dest, #16
		jmp	#write_and_nexti
do_rdlong
		test	dest, iobase wz
	if_nz	jmp	read_io
		add	dest, membase
		rdlong	dest, dest
		jmp	#write_and_nexti

read_io
		'' read from COG memory
		shr	dest, #2	' convert from bytes to longs
		movs	:readcog, dest
		nop
:readcog	mov	dest, 0-0
		jmp	#write_and_nexti
		
		''
		'' re-order bits of opcode so that it is
		'' an s-type immediate value
get_s_imm
		mov	temp, opcode
		shr	temp, #7
		and	temp, #$1f
		sar	opcode, #20
		andn	opcode, #$1f
		or	opcode, temp	' opcode has offset
get_s_imm_ret	ret

storetab
		jmp	#do_wrbyte
		jmp	#do_wrword
		jmp	#do_wrlong
		jmp	#illegalinstr
		
storeop
		call	#getrs2
		movs	:set1, rs2
		call	#getrs1
		movs	:set2, rs1
		call	#getfunct3
:set1		mov	dest, 0-0	' set dest to value of rs2 (value to store)
:set2		mov	rs1, 0-0	' set rs1 to address of memory
		test	funct3, #4 wz	' check for signed/unsigned; Z is set for signed
	if_nz	jmp	#illegalinstr
		and	funct3, #3
		add	funct3, #storetab

		'' extract s-type immediate
		call	#get_s_imm
		add	rs1, opcode	' find address
		jmp	funct3		' go do store

iobase		long	$f0000000
do_wrlong
		test	rs1, iobase wz
    if_nz	jmp	#write_io
		add	rs1, membase
		wrlong	dest, rs1
		jmp	#nexti		' no writeback
		'' handle special IO stuff
write_io
		andn	rs1, iobase
		shr	rs1, #2 wz
    if_nz	jmp	#doiocog
    		mov	newcmd, dest
		call	#sendcmd
		call	#waitcmdclear
		jmp	#nexti
doiocog
		movd	:writecog, rs1
		nop
:writecog	mov	0-0, dest
		jmp	#nexti

do_wrword
		add	rs1, membase
		wrword	dest, rs1
		jmp	#nexti		' no writeback
do_wrbyte
		add	rs1, membase
		wrbyte	dest, rs1
		jmp	#nexti		' no writeback

''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' implement conditional branches
''''''''''''''''''''''''''''''''''''''''''''''''''''''''
condbranch
		call	#getrs1
		movs	:bfetch1, rs1
		call	#getrs2
		movs	:bfetch2, rs2
:bfetch1	mov	rs1, 0-0
:bfetch2	mov	rs2, 0-0
		call	#getfunct3
		call	#get_s_imm	' opcode now contains s-type immediate
		test	opcode, #1 wc	' get low bit into carry
		muxc	opcode, bit11	' copy up to bit 11
		andn	opcode, #1	' clear low bit
		add	opcode, pc
		sub	opcode, #4	' opcode now has desired destination
		shr	funct3, #1 wc
	if_c	mov	temp, pc	' if low bit was set, invert sense
	if_c	mov	pc, opcode
	if_c	mov	opcode, temp

		'' at this point, check for type of compares
		'' C will be set for an unsigned compare, clear for signed
		'' Z will be set for test ==, clear for test <
		shr	funct3, #1 wc,wz	' check for signed compare
	if_c	movi	docmp, #CMP_UNSIGNED
	if_nc	movi	docmp, #CMP_SIGNED
	if_nz	jmp	#jlt
		call	#docmp
	if_z	mov	pc, opcode
		jmp	#nexti
jlt
		call	#docmp
	if_b	mov	pc, opcode
		jmp	#nexti
docmp
		cmp	rs1, rs2 wc, wz	' replaced with actual instruction above
docmp_ret	ret

''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' unsigned multiply rs1 * rs2 -> (dest, desth)
''''''''''''''''''''''''''''''''''''''''''''''''''''''''
imp_mul
		call	#umul
		jmp	#write_and_nexti
imp_muluh	call	#umul
		mov	dest, desth
		jmp	#write_and_nexti

imp_divu	call	#udiv
		jmp	#write_and_nexti
imp_remu	call	#udiv
		mov	dest, desth
		jmp	#write_and_nexti

imp_rem
		mov	divflags, #4
		jmp	#dodiv
imp_div
		mov	divflags, #0
dodiv
		abs	dest, dest wc
		muxc	divflags, #1
		abs	rs2, rs2 wc
		muxc	divflags, #2
		call	#udiv
		test	divflags, #4 wc	' do we want remainder?
	if_c	jmp	#dorem
		test	divflags, #3 wc	' if both have same sign parity will be even, so c 0
	if_c	neg	dest, dest
		jmp	#write_and_nexti
dorem
		mov	desth, dest
		test	divflags, #1 wc	' remainder has sign of rs1
	if_c	neg	dest, dest
		jmp	#write_and_nexti

umul
		mov	rs1, dest
		mov	dest, #0
		mov	desth, #0
		mov	temp, #0
umul_loop
		shr	rs2, #1 wc, wz
  if_nc		jmp	#umul_skip_add
  		add	dest, rs1 wc
		addx	desth, temp
umul_skip_add
  		add	rs1, rs1 wc
		addx	temp, temp
  if_nz		jmp	#umul_loop

umul_ret	ret

		'' calculate dest / rs2; result in dest, remainder in desth
udiv
		mov	rs1, dest
		cmp	rs2, #0 wz
  if_z		jmp	#div_by_zero

  		mov	dest, #0
		mov	desth, #1	' shift count
		
  		' align divisor to leftmost bit
:alignlp	
		shl	rs2, #1	 wc
		cmp	rs2, rs1 wz, wc
  if_c_or_z	add	desth, #1
  if_c		jmp	#:alignlp
		

:div_loop
		shr	rs2, #1		' halve divison
		cmpsub	rs1, rs2 wc
		rcl	dest, #1
		shr	rs2, #1
		djnz	desth, #:div_loop
		mov	desth, rs2

		mov	info1, dest
		mov	info2, desth
udiv_ret	ret

div_by_zero
		neg	dest, #1
		mov	desth, rs1
		jmp	udiv_ret

''''''''''''''''''''''''''''''''''''''''''''''''''''''''
' debug routines
''''''''''''''''''''''''''''''''''''''''''''''''''''''''

singlestep
		call	#dumpregs
		mov	newcmd, #1	' single step command
		call	#sendcmd	' send info
		call	#waitcmdclear	' wait for response
singlestep_ret	ret
		
dumpregs
		mov	cogaddr, #x0
		mov	hubaddr, dbgreg_addr
		mov	hubcnt, #36*4
		sub	pc, membase	' adjust for VM
		call	#cogxfr_write
		add	pc, membase	' adjust for VM
dumpregs_ret
		ret

newcmd		long 0
sendcmd
		call	#waitcmdclear
		wrlong	newcmd, cmd_addr
sendcmd_ret	ret
		
waitcmdclear
		rdlong	temp, cmd_addr
		cmp	temp, #0 wz
	if_nz	jmp	#waitcmdclear	' far end is still processing last command
waitcmdclear_ret
		ret
		
	
'------------------------------------------------------------------------------
' routines for fast transfer of COG memory to/from hub
' "hubaddr"   is the HUB memory address
' "cogaddr"   is the COG memory address
' "hubcnt"    is the number of *bytes* to transfer
' '
' The idea is based on code posted by Kuroneko in the
' "Fastest possible memory transfer" thread on the
' Parallax forums, modified slightly for arbitrary buffers.
' Note that the number of longs must be a multiple of 2
'------------------------------------------------------------------------------

' NOTE: the instructions at lbuf0 and lbuf1 can be destroyed if
' we count down below 0 (where the cache starts) so we have to
' refresh them each time
' we have to set up for read/write anyway, so this isn't too big
' a deal

wrins		wrlong	0-0, hubaddr

cogxfr_write
		mov	lbuf0, wrins
		jmp	#doxfer

rdins	   	rdlong	0-0, hubaddr
cogxfr_read
  		mov	lbuf0, rdins
doxfer
		mov	lbuf1, lbuf0
		add	hubcnt, #7
		andn	hubcnt, #7	' round up
		' point to last byte in HUB buffer
		add	hubaddr, hubcnt
		sub	hubaddr, #1
		' point to last longs in cog memory
		shr	hubcnt, #2      ' convert to longs
		add	cogaddr, hubcnt
		sub	cogaddr, #1
		movd	lbuf0, cogaddr
		sub	cogaddr, #1
		movd	lbuf1, cogaddr
		sub	hubcnt, #2
		movi	hubaddr, hubcnt	' set high bits of hub address

lbuf0		rdlong	0-0, hubaddr
		sub	lbuf0, dst2
		sub	hubaddr, i2s7 wc
lbuf1		rdlong  0-0, hubaddr
		sub	lbuf1, dst2
if_nc		djnz	hubaddr, #lbuf0
cogxfr_read_ret
cogxfr_write_ret
		ret
		'' initialized data and presets
dst2		long	2 << 9
i2s7		long	(2<<23) | 7

temp		long 0
dest		long 0
desth		long 0	' high word of result for mul/div
dbgreg_addr	long 0	' address where registers go in HUB during debug
cmd_addr	long 0	' address of HUB command word
membase		long 0	' base of emulated RAM
memsize		long 0	' size of emulated RAM
hubaddr		long 0
cogaddr		long 0
hubcnt		long 0

		'' registers
		'' pc must follow x0-x31
		'' next one after is also displayed in debug
x0		long	0[32]
pc		long	0
opcode		long	0
info1		long	0	' debug info
info2		long	0	' debug info

rd		long	0
rs1		long	0
rs2		long	0
funct3		long	0
divflags	long	0

		fit	$1c0	'$1F0 is whole thing
