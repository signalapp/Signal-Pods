//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSString (OWS)

- (NSString *)ows_stripped;

- (NSString *)digitsOnly;

@property (nonatomic, readonly) BOOL hasAnyASCII;
@property (nonatomic, readonly) BOOL isOnlyASCII;

/// Trims and filters a string for display
- (NSString *)filterStringForDisplay;

/// Filters a substring for display, but does not trim it.
- (NSString *)filterSubstringForDisplay;

- (NSString *)filterFilename;

@property (nonatomic, readonly) NSString *withoutBidiControlCharacters;
@property (nonatomic, readonly) NSString *ensureBalancedBidiControlCharacters;
@property (nonatomic, readonly) NSString *bidirectionallyBalancedAndIsolated;

- (BOOL)isValidE164;

+ (NSString *)formatDurationSeconds:(uint32_t)durationSeconds useShortFormat:(BOOL)useShortFormat;

- (NSString *)stringByPrependingCharacter:(unichar)character;
- (NSString *)stringByAppendingCharacter:(unichar)character;

@end

NS_ASSUME_NONNULL_END
