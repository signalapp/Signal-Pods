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

#import "Curve25519.h"
#import "Curve25519Kit.h"
#import "Ed25519.h"

FOUNDATION_EXPORT double Curve25519KitVersionNumber;
FOUNDATION_EXPORT const unsigned char Curve25519KitVersionString[];

