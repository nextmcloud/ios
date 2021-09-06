#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "Tealium-Autotracking-Bridging-Header.h"
#import "UIApplication+TealiumTracker.h"
#import "UIViewController+TealiumTracker.h"

FOUNDATION_EXPORT double TealiumSwiftVersionNumber;
FOUNDATION_EXPORT const unsigned char TealiumSwiftVersionString[];

