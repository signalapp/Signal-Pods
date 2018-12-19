//
//  MTLReflection.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import "MTLReflection.h"
#import <objc/runtime.h>

SEL MTLSelectorWithKeyPattern(NSString *key, const char *suffix) {
	NSUInteger keyLength = [key maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger suffixLength = strlen(suffix);

	char selector[keyLength + suffixLength + 1];

	BOOL success = [key getBytes:selector maxLength:keyLength usedLength:&keyLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, key.length) remainingRange:NULL];
	if (!success) return NULL;

	memcpy(selector + keyLength, suffix, suffixLength);
	selector[keyLength + suffixLength] = '\0';

	return sel_registerName(selector);
}

// BEGIN ORM-PERF-1
// Commented out by mkirk as part of ORM perf optimizations.
// The `MTLSelectorWithCapitalizedKeyPattern` can be quite expensive in aggregate
// and we're not using the reflective features that require it.
// If we later want to use this feature, we'll need to carefully evaluate the perf
// implications on large migrations.
//SEL MTLSelectorWithCapitalizedKeyPattern(const char *prefix, NSString *key, const char *suffix) {
//    NSUInteger prefixLength = strlen(prefix);
//    NSUInteger suffixLength = strlen(suffix);
//
//    NSString *initial = [key substringToIndex:1].uppercaseString;
//    NSUInteger initialLength = [initial maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
//
//    NSString *rest = [key substringFromIndex:1];
//    NSUInteger restLength = [rest maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
//
//    char selector[prefixLength + initialLength + restLength + suffixLength + 1];
//    memcpy(selector, prefix, prefixLength);
//
//    BOOL success = [initial getBytes:selector + prefixLength maxLength:initialLength usedLength:&initialLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, initial.length) remainingRange:NULL];
//    if (!success) return NULL;
//
//    success = [rest getBytes:selector + prefixLength + initialLength maxLength:restLength usedLength:&restLength encoding:NSUTF8StringEncoding options:0 range:NSMakeRange(0, rest.length) remainingRange:NULL];
//    if (!success) return NULL;
//
//    memcpy(selector + prefixLength + initialLength + restLength, suffix, suffixLength);
//    selector[prefixLength + initialLength + restLength + suffixLength] = '\0';
//
//    return sel_registerName(selector);
//}
// END ORM-PERF-1
