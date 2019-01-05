//
//  MTLReflection.h
//  Mantle
//
//  Created by Justin Spahr-Summers on 2013-03-12.
//  Copyright (c) 2013 GitHub. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Creates a selector from a key and a constant string.
///
/// key    - The key to insert into the generated selector. This key should be in
///          its natural case.
/// suffix - A string to append to the key as part of the selector.
///
/// Returns a selector, or NULL if the input strings cannot form a valid
/// selector.
SEL MTLSelectorWithKeyPattern(NSString *key, const char *suffix) __attribute__((pure, nonnull(1, 2)));


// BEGIN ORM-PERF-1
// Commented out by mkirk as part of ORM perf optimizations.
// The `MTLSelectorWithCapitalizedKeyPattern` can be quite expensive in aggregate
// and we're not using the reflective features that require it.
// If we later want to use this feature, we'll need to carefully evaluate the perf
// implications on large migrations.
//
/// Creates a selector from a key and a constant prefix and suffix.
///
/// prefix - A string to prepend to the key as part of the selector.
/// key    - The key to insert into the generated selector. This key should be in
///          its natural case, and will have its first letter capitalized when
///          inserted.
/// suffix - A string to append to the key as part of the selector.
///
/// Returns a selector, or NULL if the input strings cannot form a valid
/// selector.
//SEL MTLSelectorWithCapitalizedKeyPattern(const char *prefix, NSString *key, const char *suffix) __attribute__((pure, nonnull(1, 2, 3)));
//
// END ORM-PERF-1
