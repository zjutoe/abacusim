#include <unistd.h>
#include <sys/types.h>
#include <stdint.h>

uint32_t do_getegid()
{
	return getegid();
}

