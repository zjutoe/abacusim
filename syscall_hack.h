#ifndef SYSCALL_HACK_H
#define SYSCALL_HACK_H

#define TARGET_MIPS
#define TARGET_ABI32
#define TARGET_ABI_MIPSO32
#define CONFIG_USER_ONLY
//#define TARGET_LONG_BITS (sizeof(long)*8)
#define TARGET_LONG_BITS 32
#define CONFIG_UNAME_RELEASE "abacusim"

#ifndef TARGET_LONG_BITS
#error TARGET_LONG_BITS must be defined before including this header
#endif

#define TARGET_LONG_SIZE (TARGET_LONG_BITS / 8)

/* target_ulong is the type of a virtual address */
#if TARGET_LONG_SIZE == 4
typedef int32_t target_long;
typedef uint32_t target_ulong;
#define TARGET_FMT_lx "%08x"
#define TARGET_FMT_ld "%d"
#define TARGET_FMT_lu "%u"
#elif TARGET_LONG_SIZE == 8
typedef int64_t target_long;
typedef uint64_t target_ulong;
#define TARGET_FMT_lx "%016" PRIx64
#define TARGET_FMT_ld "%" PRId64
#define TARGET_FMT_lu "%" PRIu64
#else
#error TARGET_LONG_SIZE undefined
#endif

// BEGIN: qemu-common.h
#ifndef O_LARGEFILE
#define O_LARGEFILE 0
#endif
#ifndef O_BINARY
#define O_BINARY 0
#endif
#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif
#ifndef ENOMEDIUM
#define ENOMEDIUM ENODEV
#endif
#if !defined(ENOTSUP)
#define ENOTSUP 4096
#endif
#if !defined(ECANCELED)
#define ECANCELED 4097
#endif
#if !defined(EMEDIUMTYPE)
#define EMEDIUMTYPE 4098
#endif
#ifndef TIME_MAX
#define TIME_MAX LONG_MAX
#endif
// END: qemu-common.h

// BEGIN: qemu.h
#define VERIFY_READ 0
#define VERIFY_WRITE 1 /* implies read access */
#define MAX_ARG_PAGES 33
// END: qemu.h

// BEGIN: qemu/osdep.h
#define IOV_MAX 1024
// END: qemu/hosdep.h

// BEGIN: cpu-all.h
#define TARGET_PAGE_SIZE (1 << TARGET_PAGE_BITS)
#define TARGET_PAGE_MASK ~(TARGET_PAGE_SIZE - 1)
#define TARGET_PAGE_ALIGN(addr) (((addr) + TARGET_PAGE_SIZE - 1) & TARGET_PAGE_MASK)

/* same as PROT_xxx */
#define PAGE_READ      0x0001
#define PAGE_WRITE     0x0002
#define PAGE_EXEC      0x0004
#define PAGE_BITS      (PAGE_READ | PAGE_WRITE | PAGE_EXEC)
#define PAGE_VALID     0x0008
/* original state of the write flag (used when tracking self-modifying
   code */
#define PAGE_WRITE_ORG 0x0010
#if defined(CONFIG_BSD) && defined(CONFIG_USER_ONLY)
/* FIXME: Code that sets/uses this is broken and needs to go away.  */
#define PAGE_RESERVED  0x0020
#endif

// END: cpu-all.h


#include "abitypes.h"
#include "syscall_defs.h"
#include "mips-defs.h"
#include "spinlock.h"

/* types enums definitions */
typedef enum argtype {
	TYPE_NULL,
	TYPE_CHAR,
	TYPE_SHORT,
	TYPE_INT,
	TYPE_LONG,
	TYPE_ULONG,
	TYPE_PTRVOID, /* pointer on unknown data */
	TYPE_LONGLONG,
	TYPE_ULONGLONG,
	TYPE_PTR,
	TYPE_ARRAY,
	TYPE_STRUCT,
	TYPE_OLDDEVT,
} argtype;

#define MK_PTR(type) TYPE_PTR, type
#define MK_ARRAY(type, size) TYPE_ARRAY, size, type
#define MK_STRUCT(id) TYPE_STRUCT, id

#define THUNK_TARGET 0
#define THUNK_HOST   1

typedef struct {
	/* standard struct handling */
	const argtype *field_types;
	int nb_fields;
	int *field_offsets[2];
	/* special handling */
	void (*convert[2])(void *dst, const void *src);
	int size[2];
	int align[2];
	const char *name;
} StructEntry;

/* Translation table for bitmasks... */
typedef struct bitmask_transtbl {
	unsigned intx86_mask;
	unsigned intx86_bits;
	unsigned intalpha_mask;
	unsigned intalpha_bits;
} bitmask_transtbl;


#define MAX_STRUCTS 128
/* XXX: make it dynamic */
StructEntry struct_entries[MAX_STRUCTS];

#undef offsetof
#if ( defined ( __GNUC__ ) && ( __GNUC__ > 3 ) )
#define offsetof(TYPE, MEMBER) __builtin_offsetof(TYPE, MEMBER)
#else
#define offsetof(TYPE, MEMBER) ((size_t) &((TYPE *)0)->MEMBER)
#endif

#define PRIx64 "llx"


/* Functions for accessing guest memory.  The tget and tput functions
   read/write single values, byteswapping as necessary.  The lock_user
   gets a pointer to a contiguous area of guest memory, but does not perform
   and byteswapping.  lock_user may return either a pointer to the guest
   memory, or a temporary buffer.  */

/* Lock an area of guest memory into the host.  If copy is true then the
   host area will have the same contents as the guest.  */
static inline void *lock_user(int type, abi_ulong guest_addr, long len, int copy)
{
	if (!access_ok(type, guest_addr, len))
		return NULL;
#ifdef DEBUG_REMAP
	{
		void *addr;
		addr = malloc(len);
		if (copy)
			memcpy(addr, g2h(guest_addr), len);
		else
			memset(addr, 0, len);
		return addr;
	}
#else
	return g2h(guest_addr);
#endif
}

/* Unlock an area of guest memory.  The first LEN bytes must be
   flushed back to guest memory. host_ptr = NULL is explicitly
   allowed and does nothing. */
static inline void unlock_user(void *host_ptr, abi_ulong guest_addr,
                               long len)
{

#ifdef DEBUG_REMAP
	if (!host_ptr)
		return;
	if (host_ptr == g2h(guest_addr))
		return;
	if (len > 0)
		memcpy(g2h(guest_addr), host_ptr, len);
	free(host_ptr);
#endif
}

/* Return the length of a string in target memory or -TARGET_EFAULT if
   access error. */
abi_long target_strlen(abi_ulong gaddr);

/* Like lock_user but for null terminated strings.  */
static inline void *lock_user_string(abi_ulong guest_addr)
{
	abi_long len;
	len = target_strlen(guest_addr);
	if (len < 0)
		return NULL;
	return lock_user(VERIFY_READ, guest_addr, (long)(len + 1), 1);
}

/* Helper macros for locking/ulocking a target struct.  */
#define lock_user_struct(type, host_ptr, guest_addr, copy)\
	(host_ptr = lock_user(type, guest_addr, sizeof(*host_ptr), copy))
#define unlock_user_struct(host_ptr, guest_addr, copy)\
	unlock_user(host_ptr, guest_addr, (copy) ? sizeof(*host_ptr) : 0)



#endif //SYSCALL_HACK_H
