/*
 * Copyright (c) 2014-2015 MongoDB, Inc.
 * Copyright (c) 2008-2014 WiredTiger, Inc.
 *	All rights reserved.
 *
 * See the file LICENSE for redistribution information.
 */

/*
 * Spin locks:
 *
 * These used for cases where fast mutual exclusion is needed (where operations
 * done while holding the spin lock are expected to complete in a small number
 * of instructions.
 */

#if SPINLOCK_TYPE == SPINLOCK_GCC

/* Default to spinning 1000 times before yielding. */
#ifndef WT_SPIN_COUNT
#define	WT_SPIN_COUNT WT_THOUSAND
#endif

/*
 * __wt_spin_init --
 *      Initialize a spinlock.
 */
static inline int
__wt_spin_init(WT_SESSION_IMPL *session, WT_SPINLOCK *t, const char *name)
{
	WT_UNUSED(session);
	WT_UNUSED(name);

	t->lock = 0;
	return (0);
}

/*
 * __wt_spin_destroy --
 *      Destroy a spinlock.
 */
static inline void
__wt_spin_destroy(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	t->lock = 0;
}

/*
 * __wt_spin_trylock --
 *      Try to lock a spinlock or fail immediately if it is busy.
 */
static inline int
__wt_spin_trylock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	int ret;
	WT_UNUSED(session);

	WT_BEGIN_SPINLOCK(session, t);
	ret =  (__sync_lock_test_and_set(&t->lock, 1) == 0 ? 0 : EBUSY);
	WT_END_SPINLOCK(session, t);

	return ret;
}

/*
 * __wt_spin_lock --
 *      Spin until the lock is acquired.
 */
static inline void
__wt_spin_lock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	int i;

	WT_BEGIN_SPINLOCK(session, t);

	while (__sync_lock_test_and_set(&t->lock, 1)) {
		for (i = 0; t->lock && i < WT_SPIN_COUNT; i++)
			WT_PAUSE();
		if (t->lock)
			__wt_yield(session);
	}
	WT_END_SPINLOCK(session, t);
}

/*
 * __wt_spin_unlock --
 *      Release the spinlock.
 */
static inline void
__wt_spin_unlock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_BEGIN_SPINLOCK(session, t);
	__sync_lock_release(&t->lock);
	WT_END_SPINLOCK(session, t);
}

#elif SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX ||\
	SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX_ADAPTIVE

/*
 * __wt_spin_init --
 *      Initialize a spinlock.
 */
static inline int
__wt_spin_init(WT_SESSION_IMPL *session, WT_SPINLOCK *t, const char *name)
{
#if SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX_ADAPTIVE
	pthread_mutexattr_t attr;

	WT_RET(pthread_mutexattr_init(&attr));
	WT_RET(pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ADAPTIVE_NP));
	WT_RET(pthread_mutex_init(&t->lock, &attr));
#else
	WT_RET(pthread_mutex_init(&t->lock, NULL));
#endif

	t->name = name;
	t->initialized = 1;

	WT_UNUSED(session);
	return (0);
}

/*
 * __wt_spin_destroy --
 *      Destroy a spinlock.
 */
static inline void
__wt_spin_destroy(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	if (t->initialized) {
		(void)pthread_mutex_destroy(&t->lock);
		t->initialized = 0;
	}
}

#if SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX ||\
	SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX_ADAPTIVE

/*
 * __wt_spin_trylock --
 *      Try to lock a spinlock or fail immediately if it is busy.
 */
static inline int
__wt_spin_trylock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	int ret;
	WT_UNUSED(session);

	WT_BEGIN_SPINLOCK(session, t);
	ret =  (pthread_mutex_trylock(&t->lock));
	WT_END_SPINLOCK(session, t);

	return ret;
}

/*
 * __wt_spin_lock --
 *      Spin until the lock is acquired.
 */
static inline void
__wt_spin_lock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);
	WT_BEGIN_SPINLOCK(session, t);
	(void)pthread_mutex_lock(&t->lock);
	WT_END_SPINLOCK(session, t);
}
#endif

/*
 * __wt_spin_unlock --
 *      Release the spinlock.
 */
static inline void
__wt_spin_unlock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);
	WT_BEGIN_SPINLOCK(session, t);
	(void)pthread_mutex_unlock(&t->lock);
	WT_END_SPINLOCK(session, t);
}

#elif SPINLOCK_TYPE == SPINLOCK_MSVC

#define	WT_SPINLOCK_REGISTER		-1
#define	WT_SPINLOCK_REGISTER_FAILED	-2

/*
 * __wt_spin_init --
 *      Initialize a spinlock.
 */
static inline int
__wt_spin_init(WT_SESSION_IMPL *session, WT_SPINLOCK *t, const char *name)
{
	WT_UNUSED(session);

	t->name = name;
	t->initialized = 1;

	InitializeCriticalSectionAndSpinCount(&t->lock, 4000);

	return (0);
}

/*
 * __wt_spin_destroy --
 *      Destroy a spinlock.
 */
static inline void
__wt_spin_destroy(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	if (t->initialized) {
		DeleteCriticalSection(&t->lock);
		t->initialized = 0;
	}
}

/*
 * __wt_spin_trylock --
 *      Try to lock a spinlock or fail immediately if it is busy.
 */
static inline int
__wt_spin_trylock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	BOOL b = TryEnterCriticalSection(&t->lock);
	return (b == 0 ? EBUSY : 0);
}

/*
 * __wt_spin_lock --
 *      Spin until the lock is acquired.
 */
static inline void
__wt_spin_lock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	EnterCriticalSection(&t->lock);
}

/*
 * __wt_spin_unlock --
 *      Release the spinlock.
 */
static inline void
__wt_spin_unlock(WT_SESSION_IMPL *session, WT_SPINLOCK *t)
{
	WT_UNUSED(session);

	LeaveCriticalSection(&t->lock);
}

#else

#error Unknown spinlock type

#endif

/*
 * __wt_fair_trylock --
 *	Try to get a lock - give up if it is not immediately available.
 */
static inline int
__wt_fair_trylock(WT_SESSION_IMPL *session, WT_FAIR_LOCK *lock)
{
	WT_FAIR_LOCK new, old;
	int ret;

	WT_BEGIN_LOCK(session, lock);

	old = new = *lock;

	/* Exit early if there is no chance we can get the lock. */
	if (old.fair_lock_waiter != old.fair_lock_owner)
		return (EBUSY);

	/* The replacement lock value is a result of allocating a new ticket. */
	++new.fair_lock_waiter;
	ret = (__wt_atomic_cas32(
	    &lock->u.lock, old.u.lock, new.u.lock) ? 0 : EBUSY);

	WT_END_LOCK(session, lock);
	return ret;
}

/*
 * __wt_fair_lock --
 *	Get a lock.
 */
static inline int
__wt_fair_lock(WT_SESSION_IMPL *session, WT_FAIR_LOCK *lock)
{
	uint16_t ticket;
	int pause_cnt;

	WT_BEGIN_LOCK(session, lock);
	/*
	 * Possibly wrap: if we have more than 64K lockers waiting, the ticket
	 * value will wrap and two lockers will simultaneously be granted the
	 * lock.
	 */
	ticket = __wt_atomic_fetch_add16(&lock->fair_lock_waiter, 1);
	for (pause_cnt = 0; ticket != lock->fair_lock_owner;) {
		/*
		 * We failed to get the lock; pause before retrying and if we've
		 * paused enough, sleep so we don't burn CPU to no purpose. This
		 * situation happens if there are more threads than cores in the
		 * system and we're thrashing on shared resources.
		 */
		if (++pause_cnt < WT_THOUSAND)
			WT_PAUSE();
		else
			__wt_yield(session);
	}
	WT_END_LOCK(session, lock);
	return (0);
}

/*
 * __wt_fair_spinlock --
 *	Get a lock. If the lock is not available spin, don't block.
 */
static inline int
__wt_fair_spinlock(WT_SESSION_IMPL *session, WT_FAIR_LOCK *lock)
{
	uint16_t ticket;
	int pause_cnt;

	//WT_BEGIN_LOCK(session, lock);

	/*
	 * Possibly wrap: if we have more than 64K lockers waiting, the ticket
	 * value will wrap and two lockers will simultaneously be granted the
	 * lock.
	 */
	ticket = __wt_atomic_fetch_add16(&lock->fair_lock_waiter, 1);
	while (ticket != lock->fair_lock_owner)
		WT_PAUSE();

	//WT_END_LOCK(session, lock);
	return (0);
}


/*
 * __wt_fair_unlock --
 *	Release a shared lock.
 */
static inline int
__wt_fair_unlock(WT_SESSION_IMPL *session, WT_FAIR_LOCK *lock)
{
	//WT_BEGIN_LOCK(session, lock);
	/*
	 * We have exclusive access - the update does not need to be atomic.
	 */
	++lock->fair_lock_owner;
	//WT_END_LOCK(session, lock);
	return (0);
}

#ifdef HAVE_DIAGNOSTIC
/*
 * __wt_fair_islocked --
 *	Test whether the lock is currently held.
 */
static inline bool
__wt_fair_islocked(WT_SESSION_IMPL *session, WT_FAIR_LOCK *lock)
{
	WT_UNUSED(session);

	return (lock->fair_lock_waiter != lock->fair_lock_owner);
}
#endif

/*
 * The Fast-Slow lock implementation.
 */

#define WT_FS_NUMCPUS 4 /* Should be set close to the number of CPUs */
static bool __fs_init = false;

static inline int
__wt_fs_init(WT_SESSION_IMPL *session, WT_FS_LOCK *lock, const char *name)
{
	lock->name = name;
	memset(&lock->fast, 0, sizeof(WT_FAIR_LOCK));
	memset(&lock->config_lk, 0, sizeof(WT_FAIR_LOCK));

	lock->waiters_size = S2C(session)->session_size;
	lock->workers = 0;
	lock->sessions = 0;
	lock->max_sessions = 0;
	lock->max_spinners = WT_FS_NUMCPUS;

	WT_RET(__wt_calloc(session, lock->waiters_size,
			   sizeof(WT_FS_WHEAD),
			   &lock->waiter_htable));
	printf("Using fslock with %d CPUs\n", WT_FS_NUMCPUS);
	__fs_init = true;

	return 0;
}

static inline int
__fs_get_target_spinners(WT_FS_LOCK *lock) {

	int target;

	if(lock->sessions <= WT_FS_NUMCPUS)
		target = WT_FS_NUMCPUS;
	else
		target = WT_FS_NUMCPUS - lock->workers;

	if(target < 0)
		target = 1;

	return target;
}

static inline void
__wt_fs_change_sessions_workers(
	WT_SESSION_IMPL *session, WT_FS_LOCK *lock, int val_s, int val_w) {

	if(!__fs_init)
		return;

	if(val_s != 0)
		val_w = val_s;

	__wt_fair_lock(session, &lock->config_lk);
	lock->sessions += val_s;
	lock->workers += val_w;
	if(lock->sessions > lock->max_sessions)
		lock->max_sessions = lock->sessions;

	lock->max_spinners = __fs_get_target_spinners(lock);

	__wt_fair_unlock(session, &lock->config_lk);

	printf("%d workers, %d max spinners\n", lock->workers,
	       lock->max_spinners);

}

static inline int
__wt_fs_whandle_init(WT_SESSION_IMPL *session, WT_FS_WHANDLE *wh)
{
	WT_RET(__wt_cond_alloc(session,
			       "eviction wait handle", false,
			       &wh->wh_cond));
	wh->ticket = 0;
	wh->next = NULL;

	return 0;
}

static inline uint16_t
__fs_get_next_wakee(uint16_t owner_number)
{
	return (uint16_t)(owner_number + WT_FS_NUMCPUS);
}

static inline bool
__fs_should_wait(WT_FS_LOCK *lock, uint16_t ticket)
{
	return ((uint16_t)(ticket - lock->fast.fair_lock_owner)
		< lock->max_spinners) ? 0 : 1;
}

static void
__fs_maybewait(WT_SESSION_IMPL *session, uint16_t ticket, WT_FS_LOCK *lock,
	WT_FS_WHANDLE *whandle)
{
	int my_slot;
	WT_FS_WHEAD *slot_head;
	WT_FS_WHANDLE *wh = NULL, *wh_prev = NULL;

	WT_BEGIN_FUNC(session);

	/* Find my slot in the waiters array */
	//my_slot = ticket % lock->waiters_size;
	my_slot = 0;
	slot_head = &lock->waiter_htable[my_slot];

	/* Set our current ticket, so the waker can wake us up */
	whandle->ticket = ticket;

	/* Lock the slot and insert ourselves into the list.
	 * The list is sorted in the order of wait tickets.
	 */
	__wt_fair_spinlock(session, &slot_head->lk);
	whandle->next = slot_head->first_waiter;
	slot_head->first_waiter = whandle;
	__wt_fair_unlock(session, &slot_head->lk);

        /* Grab the lock, theck the condition, and atomically
	 * go to sleep if it is true.
	 */
	__wt_spin_lock(session, (WT_SPINLOCK*)&whandle->wh_cond->mtx);
	if(__fs_should_wait(lock, ticket))
	{
		bool signalled;
		printf("Waiter %d is sleeping\n", ticket);
		__wt_cond_wait_signal(session, whandle->wh_cond,
				      0, &signalled, true /*locked*/);
	}
	__wt_spin_unlock(session, (WT_SPINLOCK*)&whandle->wh_cond->mtx);

	/* We don't recheck the condition upon awakening. Once the lock owner's
	 * number got close to us, it cannot go back to being far.
	 */
#if 0
	__wt_fair_spinlock(session, &slot_head->lk);
	for(wh = slot_head->first_waiter; wh != NULL; wh = wh->next)
	{
		if(wh != whandle)
		{
			wh_prev = wh;
			continue;
		}
		else
		{
			if(wh_prev)
				wh_prev->next = wh->next;
			else
				slot_head->first_waiter = wh->next;
			whandle->next = NULL;
			break;
		}
	}
	__wt_fair_unlock(session, &slot_head->lk);
#endif
	WT_END_FUNC(session);
}

/*
 * Wake the next waiter whose ticket number indicates that it should begin
 * spinning.
 */
static void
__fs_wake_next_waiters(WT_SESSION_IMPL *session, WT_FS_LOCK *lock,
	int num_to_wake) {

	WT_FS_WHEAD *slot_head;
	WT_FS_WHANDLE *wh = NULL;
	int i;

	WT_BEGIN_FUNC(session);

	slot_head = &lock->waiter_htable[0];

	for(i = 0; i < num_to_wake; i++) {
		/* The largest ticket that we can have is the largest
		 * unsigned 16-bit number. So we set min initially to be one
		 * greater than that.
		 */
		WT_FS_WHANDLE *min_wh = NULL, *prev = NULL, *prev_min = NULL;
		int min = 65536;

		__wt_fair_spinlock(session, &slot_head->lk);

		for(wh = slot_head->first_waiter; wh != NULL;
		    prev = wh, wh = wh->next) {

			if(wh->ticket < min) {
				min = wh->ticket;
				min_wh = wh;
				prev_min = prev;
			}
		}
		if(min_wh) {

			/* Remove the wakee from the list */
			if(prev_min == NULL)
				slot_head->first_waiter = min_wh->next;
			else {
				WT_ASSERT(session, prev_min != min_wh);
				prev_min->next = min_wh->next;
			}
			min_wh->next = NULL;
		}
		__wt_fair_unlock(session, &slot_head->lk);

		if(min_wh) {
			__wt_cond_signal(session, min_wh->wh_cond, false);
			printf("Woke up %dth item: %d ticket\n",
			       i, min_wh->ticket);
		}
	}
	WT_END_FUNC(session);
}

 static inline int
 __fs_get_num_wakees(WT_SESSION_IMPL *session, WT_FS_LOCK *lock) {

	 int target_spinners;
	 int target_wakees;

	 __wt_fair_lock(session, &lock->config_lk);

	 target_spinners = __fs_get_target_spinners(lock);
	 target_wakees = target_spinners - lock->max_spinners;

	 __wt_fair_unlock(session, &lock->config_lk);

	 if(target_wakees < 1)
		 target_wakees = 1;

	 return target_wakees;
 }

static inline int
__wt_fs_lock(WT_SESSION_IMPL *session, WT_FS_LOCK *lock, WT_FS_WHANDLE *whandle)
{
	uint16_t ticket;
	int pause_cnt;

	WT_BEGIN_LOCK(session, lock);

	/* We are about to wait on a lock, so we are no longer considered a
	 * worker.
	 */
	if(lock->max_sessions > WT_FS_NUMCPUS)
		__wt_fs_change_sessions_workers(session, lock, 0, -1);

	/*
	 * Possibly wrap: if we have more than 64K lockers waiting, the ticket
	 * value will wrap and two lockers will simultaneously be granted the
	 * lock.
	 */
	ticket = __wt_atomic_fetch_add16(&lock->fast.fair_lock_waiter, 1);

retry:
	while( ticket != lock->fast.fair_lock_owner &&
	       !__fs_should_wait(lock, ticket))
		WT_PAUSE();

	if(ticket == lock->fast.fair_lock_owner)
		goto done;
	else
	{
		__fs_maybewait(session, ticket, lock, whandle);
		goto retry;
	}
done:
	/* We acquired the lock, so we are now considered a worker. */
	if(lock->max_sessions > WT_FS_NUMCPUS)
		__wt_fs_change_sessions_workers(session, lock, 0, 1);

	WT_END_LOCK(session, lock);
	return 0;
}

static inline int
__wt_fs_unlock(WT_SESSION_IMPL *session, WT_FS_LOCK *lock)
{
	uint16_t wakee_ticket;
	int num_towake;

	WT_BEGIN_LOCK(session, lock);

	/* Unlock the "fast" portion of the lock. */
	++lock->fast.fair_lock_owner;

	if(lock->max_sessions > WT_FS_NUMCPUS) {
		num_towake = __fs_get_num_wakees(session, lock);
		__fs_wake_next_waiters(session, lock, num_towake);
	}

	WT_END_LOCK(session, lock);
	return 0;
}

