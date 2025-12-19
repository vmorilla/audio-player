#ifndef _DEBUG_H_
#define _DEBUG_H_

#include <stdint.h>
#include <stdbool.h>

#ifdef DEBUG

/** Assert and trace strings can include formatted parameters:
 * %c - char
 * %s - string
 * %f - 32 bits float
 * %i - 16 bits signed integer
 * %d - 16 bits signed integer
 * %u - 16 bits unsigned integer
 * %x - 16 bits hexadecimal
 * %X - 16 bits hexadecimal (uppercase)
 * Mind that all arguments are passed as 16 bits, except for 'f' (32 bits)
 * This is the behaviour of varargs in C17 for the Z80 architecture
 * **/
#define assert(condition, ...) _assert(condition, __VA_ARGS__)
#define trace(...) _trace(__VA_ARGS__)

void _assert(bool condition, const char *message, ...);
void _trace(const char *message, ...);

#else

#define assert(condition, ...) ((void)0)
#define trace(...) ((void)0)

#endif

#endif