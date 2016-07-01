/* DO NOT EDIT: automatically built by dist/s_prototypes. */

extern int __wt_win_directory_list(WT_FILE_SYSTEM *file_system, WT_SESSION *wt_session, const char *directory, const char *prefix, char ***dirlistp, uint32_t *countp);
extern int __wt_win_directory_list_free(WT_FILE_SYSTEM *file_system, WT_SESSION *wt_session, char **dirlist, uint32_t count);
extern int __wt_dlopen(WT_SESSION_IMPL *session, const char *path, WT_DLH **dlhp);
extern int __wt_dlsym(WT_SESSION_IMPL *session, WT_DLH *dlh, const char *name, bool fail, void *sym_ret);
extern int __wt_dlclose(WT_SESSION_IMPL *session, WT_DLH *dlh);
extern int __wt_win_fs_size(WT_FILE_SYSTEM *file_system, WT_SESSION *wt_session, const char *name, wt_off_t *sizep);
extern int __wt_os_win(WT_SESSION_IMPL *session);
extern int __wt_getenv(WT_SESSION_IMPL *session, const char *variable, const char **envp);
extern int __wt_win_map(WT_FILE_HANDLE *file_handle, WT_SESSION *wt_session, void *mapped_regionp, size_t *lenp, void *mapped_cookiep);
extern int __wt_win_unmap(WT_FILE_HANDLE *file_handle, WT_SESSION *wt_session, void *mapped_region, size_t length, void *mapped_cookie);
extern int __wt_cond_alloc(WT_SESSION_IMPL *session, const char *name, bool is_signalled, WT_CONDVAR **condp);
extern int __wt_cond_wait_signal( WT_SESSION_IMPL *session, WT_CONDVAR *cond, uint64_t usecs, bool *signalled);
extern int __wt_cond_signal(WT_SESSION_IMPL *session, WT_CONDVAR *cond);
extern int __wt_cond_destroy(WT_SESSION_IMPL *session, WT_CONDVAR **condp);
extern int __wt_once(void (*init_routine)(void));
extern int __wt_get_vm_pagesize(void);
extern bool __wt_absolute_path(const char *path);
extern const char *__wt_path_separator(void);
extern bool __wt_has_priv(void);
extern void __wt_stream_set_line_buffer(FILE *fp);
extern void __wt_stream_set_no_buffer(FILE *fp);
extern void __wt_sleep(WT_SESSION_IMPL *session, uint64_t seconds, uint64_t micro_seconds);
extern int __wt_thread_create(WT_SESSION_IMPL *session, wt_thread_t *tidret, WT_THREAD_CALLBACK(*func)(void *), void *arg);
extern int __wt_thread_join(WT_SESSION_IMPL *session, wt_thread_t tid);
extern void __wt_thread_id(char *buf, size_t buflen);
extern int __wt_epoch(WT_SESSION_IMPL *session, struct timespec *tsp);
extern DWORD __wt_getlasterror(void);
extern int __wt_map_windows_error(DWORD windows_error);
extern const char *__wt_formatmessage(WT_SESSION_IMPL *session, DWORD windows_error);
extern void __wt_yield(WT_SESSION_IMPL *session);