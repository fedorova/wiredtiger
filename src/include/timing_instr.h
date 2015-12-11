/*
 * Use these macros to log function begin and end timestamps. Besides the
 * session id, the logging macro optionally takes a pointer, which will
 * also appear in the log. This is useful for logging the addresses of
 * locks.
 *
 * Timing instrumentation will work correctly only if WT_END_FUNC is inserted
 * at every potential exit point of the function being traced. To make this
 * easier, use WT_RET_DONE macro together with the ret_done label.
 */

#ifdef HAVE_TIMING
#define WT_BEGIN_FUNC(session)						       \
	{	                                                               \
	struct timespec ts_begin, ts_end;			               \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)	{		               \
	        if(session->timing_log !=NULL) {                               \
        		fprintf(session->timing_log, "--> %s %d %ld\n",   \
				__func__, (session)->id, 		       \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec);			       \
	        }                                                              \
	}                                                                      \
	}
#define WT_END_FUNC(session)					               \
	{	                                                               \
	struct timespec ts_begin, ts_end;                                      \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)			               \
	        if(session->timing_log !=NULL)                                 \
        		fprintf(session->timing_log, "<-- %s %d %ld\n",   \
				__func__, (session)->id, 		       \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec);			       \
	}

#if SPINLOCK_TYPE == SPINLOCK_GCC
#define WT_BEGIN_SPINLOCK(session, spinlock)                                   \
	{								       \
	struct timespec ts_begin, ts_end;			               \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)			               \
	        if(session->timing_log !=NULL)                                 \
        		fprintf(session->timing_log, "--> %s %d %ld %p\n",     \
				__func__, (session)->id,  	               \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec, spinlock);		       \
         }

#define WT_END_SPINLOCK(session, spinlock)                                     \
	{								       \
	struct timespec ts_begin, ts_end;			               \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)			               \
	        if(session->timing_log !=NULL)                                 \
        		fprintf(session->timing_log, "<-- %s %d %ld %p\n",     \
				__func__, (session)->id,         	       \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec, spinlock);		       \
         }
#elif SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX ||\
	SPINLOCK_TYPE == SPINLOCK_PTHREAD_MUTEX_ADAPTIVE ||\
	SPINLOCK_TYPE == SPINLOCK_MSVC
#define WT_BEGIN_SPINLOCK(session, spinlock)                                   \
	{								       \
	struct timespec ts_begin, ts_end;			               \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)			               \
	        if(session->timing_log !=NULL)                                 \
        		fprintf(session->timing_log, "--> %s %d %ld %s\n",     \
				__func__, (session)->id,                       \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec, spinlock->name);	       \
         }

#define WT_END_SPINLOCK(session, spinlock)                                     \
	{								       \
	struct timespec ts_begin, ts_end;			               \
	if(session != NULL)                                                    \
        if(__wt_epoch(session, &ts_begin) == 0)			               \
	        if(session->timing_log !=NULL)                                 \
        		fprintf(session->timing_log, "<-- %s %d %ld %s\n",     \
				__func__, (session)->id,                       \
				ts_begin.tv_sec * WT_BILLION +		       \
				ts_begin.tv_nsec, spinlock->name);	       \
         }
#else

#error Unknown spinlock type

#endif

#else
#define WT_BEGIN_FUNC(session)
#define WT_END_FUNC(session)
#define WT_BEGIN_SPINLOCK(session, spinlock)
#define WT_END_SPINLOCK(session, spinlock)
#endif
