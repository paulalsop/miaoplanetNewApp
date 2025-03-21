#ifndef sentrycrash_cppexception_patch_h
#define sentrycrash_cppexception_patch_h

#include "SentryCrashMonitor.h"

#ifdef __cplusplus
extern "C" {
#endif

// 为缺失的ucontext64_t提供一个简单的定义
#ifndef _STRUCT_UCONTEXT64
#define _STRUCT_UCONTEXT64 struct ucontext64
_STRUCT_UCONTEXT64
{
    int dummy;
};
typedef _STRUCT_UCONTEXT64 ucontext64_t;
#endif

// 提供C++异常监控API的存根
SentryCrashMonitorAPI *sentrycrashcm_cppexception_getAPI(void);

#ifdef __cplusplus
}
#endif

#endif /* sentrycrash_cppexception_patch_h */ 