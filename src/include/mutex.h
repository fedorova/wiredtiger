/*
 * Copyright (c) 2014-2015 MongoDB, Inc.
 * Copyright (c) 2008-2014 WiredTiger, Inc.
 *	All rights reserved.
 *
 * See the file LICENSE for redistribution information.
 */

/*
 * Condition variables:
 *
 * WiredTiger uses condition variables to signal between threads, and for
 * locking operations that are expected to block.
 * !!! For timing instrumentation to work, we require that the mutex is
 * followed by the name pointer.
 */
struct __wt_condvar {
	wt_mutex_t mtx;			/* Mutex */
	const char *name;		/* Mutex name for debugging */
	wt_cond_t  cond;		/* Condition variable */
	int waiters;			/* Numbers of waiters, or
					   -1 if signalled with no waiters. */
};

/*
 * !!!
 * Don't modify this structure without understanding the read/write locking
 * functions.
 */
typedef union {				/* Read/write lock */
	uint64_t u;
	struct {
		uint32_t wr;		/* Writers and readers */
	} i;
	struct {
		uint16_t writers;	/* Now serving for writers */
		uint16_t readers;	/* Now serving for readers */
		uint16_t users;		/* Next available ticket number */
		uint16_t __notused;	/* Padding */
	} s;
} wt_rwlock_t;

/*
 * Read/write locks:
 *
 * WiredTiger uses read/write locks for shared/exclusive access to resources.
 */
struct __wt_rwlock {
	const char *name;		/* Lock name for debugging */

	wt_rwlock_t rwlock;		/* Read/write lock */
};

/*
 * A light weight lock that can be used to replace spinlocks if fairness is
 * necessary. Implements a ticket-based back off spin lock.
 * The fields are available as a union to allow for atomically setting
 * the state of the entire lock.
 */
struct __wt_fair_lock {
	union {
		uint32_t lock;
		struct {
                        /* Ticket for current owner */
			volatile uint16_t owner;
                        /* Last allocated ticket */
			uint16_t waiter;
		} s;
	} u;
#define	fair_lock_owner u.s.owner
#define	fair_lock_waiter u.s.waiter
};

/*
 * Spin locks:
 *
 * WiredTiger uses spinlocks for fast mutual exclusion (where operations done
 * while holding the spin lock are expected to complete in a small number of
 * instructions).
 */
#define	SPINLOCK_GCC			0
#define	SPINLOCK_MSVC			1
#define	SPINLOCK_PTHREAD_MUTEX		2
#define	SPINLOCK_PTHREAD_MUTEX_ADAPTIVE	3

#if SPINLOCK_TYPE == SPINLOCK_GCC

struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT) __wt_spinlock {
	volatile int lock;
};

#elif SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX ||\
	SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX_ADAPTIVE ||\
	SPINLOCK_TYPE == SPINLOCK_MSVC

struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT) __wt_spinlock {
	wt_mutex_t lock;

	const char *name;		/* Statistics: mutex name */

	int8_t initialized;		/* Lock initialized, for cleanup */
};

#else

#error Unknown spinlock type

#endif

/* A fast-slow lock */

struct __wt_fs_whandle {
	uint64_t ticket;
	WT_CONDVAR *wh_cond;
	struct __wt_fs_whandle *next;
};

struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT) __wt_fs_whead {
	struct __wt_fair_lock lk;
	struct __wt_fs_whandle * volatile first_waiter;
};

struct __wt_fair_lock64 {
	/* Ticket for current owner */
	volatile uint64_t owner;
	/* Last allocated ticket */
	uint64_t waiter;
};

struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT) __wt_tas_lock {
	volatile int lk;
};

struct __wt_fs_lock {
	int num_contenders;
	const char *name;
	size_t waiters_size;
	struct __wt_fs_whead *waiter_htable;
	struct __wt_fair_lock config_lk;
	struct __wt_tas_lock tcas_lock;
	struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT)
	timespec ts_acquire;
	struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT)
	timespec ts_release;
	int num_blockers;
	struct WT_COMPILER_TYPE_ALIGN(WT_CACHE_LINE_ALIGNMENT)
	__wt_condvar *block_cond;
};

