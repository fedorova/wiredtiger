/*-
 * Copyright (c) 2014-2015 MongoDB, Inc.
 * Copyright (c) 2008-2014 WiredTiger, Inc.
 *	All rights reserved.
 *
 * See the file LICENSE for redistribution information.
 */

#include "wt_internal.h"

/*
 * __wt_yield --
 *	Yield the thread of control.
 */
void
__wt_yield(WT_SESSION *session)
{
	WT_BEGIN_FUNC(session);
	sched_yield();
	WT_END_FUNC(session);
}
