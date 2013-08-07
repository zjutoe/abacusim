#ifndef SYSCALL_HACK_H
#define SYSCALL_HACK_H

#define TARGET_MIPS
#define TARGET_ABI32
#define TARGET_ABI_MIPSO32
#define CONFIG_USER_ONLY
//#define TARGET_LONG_BITS (sizeof(long)*8)
#define TARGET_LONG_BITS 32

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

#endif //SYSCALL_HACK_H
