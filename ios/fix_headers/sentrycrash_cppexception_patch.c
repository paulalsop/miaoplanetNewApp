#include "sentrycrash_cppexception_patch.h"

// 仅提供一个简单的实现，总是禁用C++异常监控
static void setEnabled(bool isEnabled)
{
    // 不做任何事情
}

static bool isEnabled(void)
{
    return false;
}

SentryCrashMonitorAPI *sentrycrashcm_cppexception_getAPI(void)
{
    static SentryCrashMonitorAPI api = { .setEnabled = setEnabled, .isEnabled = isEnabled };
    return &api;
} 