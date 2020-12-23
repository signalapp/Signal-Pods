//
//  MTLModel.m
//  Mantle
//
//  Created by Justin Spahr-Summers on 2012-09-11.
//  Copyright (c) 2012 GitHub. All rights reserved.
//

#import "NSError+MTLModelException.h"
#import "MTLModel.h"
#import <Mantle/EXTRuntimeExtensions.h>
#import <Mantle/EXTScope.h>
#import "MTLReflection.h"
#import <objc/runtime.h>

// Used to cache the reflection performed in +propertyKeys.
static void *MTLModelCachedPropertyKeysKey = &MTLModelCachedPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all transitory
// property keys.
static void *MTLModelCachedTransitoryPropertyKeysKey = &MTLModelCachedTransitoryPropertyKeysKey;

// Associated in +generateAndCachePropertyKeys with a set of all permanent
// property keys.
static void *MTLModelCachedPermanentPropertyKeysKey = &MTLModelCachedPermanentPropertyKeysKey;

// BEGIN ORM-PERF-4
// Added by mkirk as part of ORM perf optimizations.
//
// +dictionaryValueKeys is somewhat expensive, so we follow existing library patterns
// to cache the computed reflection on the class via an associated object
//
// Used to cache the reflection performed in +dictionaryValueKeys
static void *MTLModelCachedDictionaryValueKeysKey = &MTLModelCachedDictionaryValueKeysKey;
// END ORM-PERF-4

// BEGIN ORM-PERF-2
// Commented out by mkirk as part of ORM perf optimizations.
//
// The validation NSCoding validation reflection used by Mantle is expensive, and
// we've never used it.
// If we later want to use this feature, we'll need to carefully evaluate the perf
// implications on large migrations.
//
// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated. This value
//               must not be nil.
// key         - The name of one of `obj`s properties. This value must not be
//               nil.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
//static BOOL MTLValidateAndSetValue(id obj, NSString *key, id value, BOOL forceUpdate, NSError **error) {
//    // Mark this as being autoreleased, because validateValue may return
//    // a new object to be stored in this variable (and we don't want ARC to
//    // double-free or leak the old or new values).
//    __autoreleasing id validatedValue = value;
//
//    @try {
//        if (![obj validateValue:&validatedValue forKey:key error:error]) return NO;
//
//        if (forceUpdate || value != validatedValue) {
//            [obj setValue:validatedValue forKey:key];
//        }
//
//        return YES;
//    } @catch (NSException *ex) {
//        NSLog(@"*** Caught exception setting key \"%@\" : %@", key, ex);
//
//        // Fail fast in Debug builds.
//        #if DEBUG
//        @throw ex;
//        #else
//        if (error != NULL) {
//            *error = [NSError mtl_modelErrorWithException:ex];
//        }
//
//        return NO;
//        #endif
//    }
//}
// END ORM-PERF-2

@interface MTLModel ()

// Inspects all properties of returned by +propertyKeys using
// +storageBehaviorForPropertyWithKey and caches the results.
+ (void)generateAndCacheStorageBehaviors;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStorageTransitory.
+ (NSSet<NSString *> *)transitoryPropertyKeys;

// Returns a set of all property keys for which
// +storageBehaviorForPropertyWithKey returned MTLPropertyStoragePermanent.
+ (NSSet<NSString *> *)permanentPropertyKeys;

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MTLModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block;

@end

@implementation MTLModel

#pragma mark Lifecycle

+ (void)generateAndCacheStorageBehaviors {
	NSMutableSet<NSString *> *transitoryKeys = [NSMutableSet set];
	NSMutableSet<NSString *> *permanentKeys = [NSMutableSet set];

	for (NSString *propertyKey in self.propertyKeys) {
		switch ([self storageBehaviorForPropertyWithKey:propertyKey]) {
			case MTLPropertyStorageNone:
				break;

			case MTLPropertyStorageTransitory:
				[transitoryKeys addObject:propertyKey];
				break;

			case MTLPropertyStoragePermanent:
				[permanentKeys addObject:propertyKey];
				break;
		}
	}

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey, transitoryKeys, OBJC_ASSOCIATION_COPY);
	objc_setAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey, permanentKeys, OBJC_ASSOCIATION_COPY);
}

+ (instancetype)modelWithDictionary:(NSDictionary<NSString *, id> *)dictionary error:(NSError **)error {
	return [[self alloc] initWithDictionary:dictionary error:error];
}

- (instancetype)init {
	// Nothing special by default, but we have a declaration in the header.
	return [super init];
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dictionary error:(NSError **)error {
	self = [self init];
	if (self == nil) return nil;

	for (NSString *key in dictionary) {
		// Mark this as being autoreleased, because validateValue may return
		// a new object to be stored in this variable (and we don't want ARC to
		// double-free or leak the old or new values).
		__autoreleasing id value = [dictionary objectForKey:key];

		if ([value isEqual:NSNull.null]) value = nil;
		// BEGIN ORM-PERF-2
		// Commented out by mkirk as part of ORM perf optimizations.
		//
		// The validation NSCoding validation reflection used by Mantle is expensive, and
		// we've never used it.
		// If we later want to use this feature, we'll need to carefully evaluate the perf
		// implications on large migrations.
		//
		// BOOL success = MTLValidateAndSetValue(self, key, value, YES, error);
		// if (!success) return nil;
		[self setValue:value forKey:key];
		// END ORM-PERF-2
	}

	return self;
}

#pragma mark Reflection

+ (void)enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
	Class cls = self;
	BOOL stop = NO;

	while (!stop && ![cls isEqual:MTLModel.class]) {
		unsigned count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);

		cls = cls.superclass;
		if (properties == NULL) continue;

		@onExit {
			free(properties);
		};

		for (unsigned i = 0; i < count; i++) {
			block(properties[i], &stop);
			if (stop) break;
		}
	}
}

+ (NSSet<NSString *> *)propertyKeys {
	NSSet<NSString *> *cachedKeys = objc_getAssociatedObject(self, MTLModelCachedPropertyKeysKey);
	if (cachedKeys != nil) return cachedKeys;

	NSMutableSet<NSString *> *keys = [NSMutableSet set];

	[self enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
		NSString *key = @(property_getName(property));

		if ([self storageBehaviorForPropertyWithKey:key] != MTLPropertyStorageNone) {
			 [keys addObject:key];
		}
	}];

	// It doesn't really matter if we replace another thread's work, since we do
	// it atomically and the result should be the same.
	objc_setAssociatedObject(self, MTLModelCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);

	return keys;
}

+ (NSSet<NSString *> *)transitoryPropertyKeys {
	NSSet<NSString *> *transitoryPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey);

	if (transitoryPropertyKeys == nil) {
		[self generateAndCacheStorageBehaviors];
		transitoryPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedTransitoryPropertyKeysKey);
	}

	return transitoryPropertyKeys;
}

+ (NSSet<NSString *> *)permanentPropertyKeys {
	NSSet<NSString *> *permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);

	if (permanentPropertyKeys == nil) {
		[self generateAndCacheStorageBehaviors];
		permanentPropertyKeys = objc_getAssociatedObject(self, MTLModelCachedPermanentPropertyKeysKey);
	}

	return permanentPropertyKeys;
}

// BEGIN ORM-PERF-4
// Added by mkirk as part of ORM perf optimizations.
//
// +dictionaryValueKeys is somewhat expensive, so we follow existing library patterns
// to cache the computed reflection on the class via an associated object
//
// Used to cache the reflection performed in +dictionaryValueKeys
+ (NSArray<NSString *> *)dictionaryValueKeys {
	NSArray<NSString *> *dictionaryValueKeys = objc_getAssociatedObject(self, MTLModelCachedDictionaryValueKeysKey);
	if (!dictionaryValueKeys) {
		NSSet<NSString *> *keys = [self.class.transitoryPropertyKeys setByAddingObjectsFromSet:self.permanentPropertyKeys];
		dictionaryValueKeys = keys.allObjects;
		objc_setAssociatedObject(self, MTLModelCachedDictionaryValueKeysKey, dictionaryValueKeys, OBJC_ASSOCIATION_COPY);
	}
	return dictionaryValueKeys;
}

- (NSDictionary<NSString *, id> *)dictionaryValue {
	NSArray<NSString *> *keys = self.class.dictionaryValueKeys;
	return [self dictionaryWithValuesForKeys:keys];
}
// END ORM-PERF-4

+ (MTLPropertyStorage)storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
	objc_property_t property = class_getProperty(self.class, propertyKey.UTF8String);

	if (property == NULL) return MTLPropertyStorageNone;

	mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
	@onExit {
		free(attributes);
	};
	
	BOOL hasGetter = [self instancesRespondToSelector:attributes->getter];
	BOOL hasSetter = [self instancesRespondToSelector:attributes->setter];
	if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
		return MTLPropertyStorageNone;
	} else if (attributes->readonly && attributes->ivar == NULL) {
		if ([self isEqual:MTLModel.class]) {
			return MTLPropertyStorageNone;
		} else {
			// Check superclass in case the subclass redeclares a property that
			// falls through
			return [self.superclass storageBehaviorForPropertyWithKey:propertyKey];
		}
	} else {
		return MTLPropertyStoragePermanent;
	}
}

#pragma mark Merging

// BEGIN ORM-PERF-1
// Commented out by mkirk as part of ORM perf optimizations.
// The `MTLSelectorWithCapitalizedKeyPattern` can be quite expensive in aggregate
// and we're not using the reflective features that require it.
// If we later want to use this feature, we'll need to carefully evaluate the perf
// implications on large migrations.
//
//- (void)mergeValueForKey:(NSString *)key fromModel:(NSObject<MTLModel> *)model {
//    NSParameterAssert(key != nil);
//
////    SEL selector = MTLSelectorWithCapitalizedKeyPattern("merge", key, "FromModel:");
////    if (![self respondsToSelector:selector]) {
////        if (model != nil) {
////            [self setValue:[model valueForKey:key] forKey:key];
////        }
////
////        return;
////    }
//
//    IMP imp = [self methodForSelector:selector];
//    void (*function)(id, SEL, id<MTLModel>) = (__typeof__(function))imp;
//    function(self, selector, model);
//}
//
//- (void)mergeValuesForKeysFromModel:(id<MTLModel>)model {
//    NSSet<NSString *> *propertyKeys = model.class.propertyKeys;
//
//    for (NSString *key in self.class.propertyKeys) {
//        if (![propertyKeys containsObject:key]) continue;
//
//        [self mergeValueForKey:key fromModel:model];
//    }
//}
// END ORM-PERF-1

// BEGIN ORM-PERF-2
// Commented out by mkirk as part of ORM perf optimizations.
//
// The validation NSCoding validation reflection used by Mantle is expensive, and
// we've never used it.
// If we later want to use this feature, we'll need to carefully evaluate the perf
// implications on large migrations.
//#pragma mark Validation
//
//- (BOOL)validate:(NSError **)error {
//    for (NSString *key in self.class.propertyKeys) {
//        id value = [self valueForKey:key];
//
//        BOOL success = MTLValidateAndSetValue(self, key, value, NO, error);
//        if (!success) return NO;
//    }
//
//    return YES;
//}
// END ORM-PERF-2

#pragma mark NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
	MTLModel *copy = [[self.class allocWithZone:zone] init];
	[copy setValuesForKeysWithDictionary:self.dictionaryValue];
	return copy;
}

#pragma mark NSObject

- (NSString *)description {
#if DEBUG
	NSDictionary<NSString *, id> *permanentProperties = [self dictionaryWithValuesForKeys:self.class.permanentPropertyKeys.allObjects];

	return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, permanentProperties];
#else
    return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
#endif
}

- (NSUInteger)hash {
	NSUInteger value = 0;

	for (NSString *key in self.class.permanentPropertyKeys) {
		value ^= [[self valueForKey:key] hash];
	}

	return value;
}

- (BOOL)isEqual:(MTLModel *)model {
	if (self == model) return YES;
	if (![model isMemberOfClass:self.class]) return NO;

	for (NSString *key in self.class.permanentPropertyKeys) {
		id selfValue = [self valueForKey:key];
		id modelValue = [model valueForKey:key];

		BOOL valuesEqual = ((selfValue == nil && modelValue == nil) || [selfValue isEqual:modelValue]);
		if (!valuesEqual) return NO;
	}

	return YES;
}

@end
