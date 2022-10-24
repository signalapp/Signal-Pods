//
//  Copyright (c) 2022 Open Whisper Systems. All rights reserved.
//

#import "NSString+OWS.h"
#import <objc/runtime.h>
#import <SignalCoreKit/SignalCoreKit-Swift.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

static void *kNSString_SSK_needsSanitization = &kNSString_SSK_needsSanitization;
static void *kNSString_SSK_sanitizedCounterpart = &kNSString_SSK_sanitizedCounterpart;
static unichar bidiLeftToRightIsolate = 0x2066;
static unichar bidiRightToLeftIsolate = 0x2067;
static unichar bidiFirstStrongIsolate = 0x2068;
static unichar bidiLeftToRightEmbedding = 0x202A;
static unichar bidiRightToLeftEmbedding = 0x202B;
static unichar bidiLeftToRightOverride = 0x202D;
static unichar bidiRightToLeftOverride = 0x202E;
static unichar bidiPopDirectionalFormatting = 0x202C;
static unichar bidiPopDirectionalIsolate = 0x2069;

@implementation NSString (OWS)

+ (NSCharacterSet *)nonPrintingCharacterSet
{
    static NSCharacterSet *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet.mutableCopy;
        [characterSet formUnionWithCharacterSet:NSCharacterSet.controlCharacterSet];
        [characterSet formUnionWithCharacterSet:[self bidiControlCharacterSet]];
        // Left-to-right and Right-to-left marks.
        [characterSet addCharactersInString:@"\u200E\u200f"];
        result = [characterSet copy];
    });
    return result;
}

+ (NSCharacterSet *)bidiControlCharacterSet
{
    static NSCharacterSet *result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *characterSet = [NSMutableCharacterSet new];
        [characterSet addCharactersInString:[NSString stringWithFormat:@"%C%C%C%C%C%C%C%C%C", bidiLeftToRightIsolate, bidiRightToLeftIsolate, bidiFirstStrongIsolate, bidiLeftToRightEmbedding, bidiRightToLeftEmbedding, bidiLeftToRightOverride, bidiRightToLeftOverride, bidiPopDirectionalFormatting, bidiPopDirectionalIsolate]];
        result = [characterSet copy];
    });
    return result;
}

- (NSString *)ows_stripped
{
    if ([self stringByTrimmingCharactersInSet:[NSString nonPrintingCharacterSet]].length < 1) {
        // If string has no printing characters, consider it empty.
        return @"";
    }
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSCharacterSet *)unsafeFilenameCharacterSet
{
    static NSCharacterSet *characterSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 0x202D and 0x202E are the unicode ordering letters
        // and can be used to control the rendering of text.
        // They could be used to construct misleading attachment
        // filenames that appear to have a different file extension,
        // for example.
        characterSet = [NSCharacterSet characterSetWithCharactersInString:@"\u202D\u202E"];
    });

    return characterSet;
}

- (NSString *)filterUnsafeFilenameCharacters
{
    NSCharacterSet *unsafeCharacterSet = [[self class] unsafeFilenameCharacterSet];
    NSRange range = [self rangeOfCharacterFromSet:unsafeCharacterSet];
    if (range.location == NSNotFound) {
        return self;
    }
    NSMutableString *filtered = [NSMutableString new];
    NSString *remainder = [self copy];
    while (range.location != NSNotFound) {
        if (range.location > 0) {
            [filtered appendString:[remainder substringToIndex:range.location]];
        }
        // The "replacement" code point.
        [filtered appendString:@"\uFFFD"];
        remainder = [remainder substringFromIndex:range.location + range.length];
        range = [remainder rangeOfCharacterFromSet:unsafeCharacterSet];
    }
    [filtered appendString:remainder];
    return filtered;
}

- (NSString *)filterSubstringForDisplay
{
    // We don't want to strip a substring before filtering.
    return self.sanitized.ensureBalancedBidiControlCharacters;
}

- (NSString *)filterStringForDisplay
{
    return self.ows_stripped.filterSubstringForDisplay;
}

- (NSString *)filterFilename
{
    return self.ows_stripped.sanitized.filterUnsafeFilenameCharacters;
}

- (NSString *)withoutBidiControlCharacters
{
    return [self stringByTrimmingCharactersInSet:[NSString bidiControlCharacterSet]];
}

- (NSString *)ensureBalancedBidiControlCharacters
{
    NSInteger isolateStartsCount = 0;
    NSInteger isolatePopCount = 0;
    NSInteger formattingStartsCount = 0;
    NSInteger formattingPopCount = 0;

    for (NSUInteger index = 0; index < self.length; index++) {
        unichar c = [self characterAtIndex:index];
        if (c == bidiLeftToRightIsolate || c == bidiRightToLeftIsolate || c == bidiFirstStrongIsolate) {
            isolateStartsCount++;
        } else if (c == bidiPopDirectionalIsolate) {
            isolatePopCount++;
        } else if (c == bidiLeftToRightEmbedding || c == bidiRightToLeftEmbedding || c == bidiLeftToRightOverride
            || c == bidiRightToLeftOverride) {
            formattingStartsCount++;
        } else if (c == bidiPopDirectionalFormatting) {
            formattingPopCount++;
        }
    }

    if (isolateStartsCount == 0 && isolatePopCount == 0
        && formattingStartsCount == 0 && formattingPopCount == 0) {
        return self;
    }
    
    NSMutableString *balancedString = [NSMutableString new];
    
    
    // If we have too many isolate pops, prepend FSI to balance
    while (isolatePopCount > isolateStartsCount) {
        [balancedString appendFormat:@"%C", bidiFirstStrongIsolate];
        isolateStartsCount++;
    }
    
    // If we have too many formatting pops, prepend LRE to balance
    while (formattingPopCount > formattingStartsCount) {
        [balancedString appendFormat:@"%C", bidiLeftToRightEmbedding];
        formattingStartsCount++;
    }
    
    [balancedString appendString:self];
    
    // If we have too many formatting starts, append PDF to balance
    while (formattingStartsCount > formattingPopCount) {
        [balancedString appendFormat:@"%C", bidiPopDirectionalFormatting];
        formattingPopCount++;
    }
    
    // If we have too many isolate starts, append PDI to balance
    while (isolateStartsCount > isolatePopCount) {
        [balancedString appendFormat:@"%C", bidiPopDirectionalIsolate];
        isolatePopCount++;
    }
    
    return [balancedString copy];
}

- (NSString *)stringByPrependingCharacter:(unichar)character
{
    return [NSString stringWithFormat:@"%C%@", character, self];
}

- (NSString *)stringByAppendingCharacter:(unichar)character
{
    return [self stringByAppendingFormat:@"%C", character];
}

- (NSString *)bidirectionallyBalancedAndIsolated
{
    if (self.length > 1) {
        unichar firstChar = [self characterAtIndex:0];
        unichar lastChar = [self characterAtIndex:self.length - 1];

        // We're already isolated, nothing to do here.
        if (firstChar == bidiFirstStrongIsolate && lastChar == bidiPopDirectionalIsolate) {
            return self;
        }
    }

    return [NSString stringWithFormat:@"%C%@%C", bidiFirstStrongIsolate, self.ensureBalancedBidiControlCharacters, bidiPopDirectionalIsolate];
}

- (NSString *)sanitized
{
    NSNumber *cachedNeedsSanitization = objc_getAssociatedObject(self, kNSString_SSK_needsSanitization);
    if (cachedNeedsSanitization != nil) {
        if (cachedNeedsSanitization.boolValue) {
            return objc_getAssociatedObject(self, kNSString_SSK_sanitizedCounterpart) ?: self;
        } else {
            return self;
        }
    }

    StringSanitizer *sanitizer = [[StringSanitizer alloc] initWithString:self];
    const BOOL needsSanitization = sanitizer.needsSanitization;
    objc_setAssociatedObject(self, kNSString_SSK_needsSanitization, @(needsSanitization), OBJC_ASSOCIATION_COPY);
    if (!needsSanitization) {
        return self;
    }
    NSString *sanitized = sanitizer.sanitized;
    objc_setAssociatedObject(self, kNSString_SSK_sanitizedCounterpart, sanitized, OBJC_ASSOCIATION_COPY);
    return sanitized;
}

+ (NSRegularExpression *)anyASCIIRegex
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"[\x00-\x7F]+"
                                                          options:0
                                                            error:&error];
        if (error || !regex) {
            // crash! it's not clear how to proceed safely, and this regex should never fail.
            OWSFail(@"could not compile regex: %@", error);
        }
    });

    return regex;
}

+ (NSRegularExpression *)onlyASCIIRegex
{
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex;
    dispatch_once(&onceToken, ^{
        NSError *error;
        regex = [NSRegularExpression regularExpressionWithPattern:@"^[\x00-\x7F]*$"
                                                          options:0
                                                            error:&error];
        if (error || !regex) {
            // crash! it's not clear how to proceed safely, and this regex should never fail.
            OWSFail(@"could not compile regex: %@", error);
        }
    });

    return regex;
}


- (BOOL)isOnlyASCII
{
    return [self.class.onlyASCIIRegex rangeOfFirstMatchInString:self
                                                        options:0
                                                          range:NSMakeRange(0, self.length)].location != NSNotFound;
}

- (BOOL)hasAnyASCII
{
    return [self.class.anyASCIIRegex rangeOfFirstMatchInString:self
                                                       options:0
                                                         range:NSMakeRange(0, self.length)].location != NSNotFound;
}

- (BOOL)isValidE164
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\+\\d+$"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error || !regex) {
        OWSFailDebug(@"could not compile regex: %@", error);
        return NO;
    }
    return [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(0, self.length)].location != NSNotFound;
}

+ (NSString *)formatDurationSeconds:(uint32_t)durationSeconds useShortFormat:(BOOL)useShortFormat
{
    NSString *amountFormat;
    uint32_t duration;

    uint32_t secondsPerMinute = 60;
    uint32_t secondsPerHour = secondsPerMinute * 60;
    uint32_t secondsPerDay = secondsPerHour * 24;
    uint32_t secondsPerWeek = secondsPerDay * 7;

    if (durationSeconds < secondsPerMinute) { // XX Seconds
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SECONDS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of seconds}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5s' not '5 s'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SECONDS",
                @"{{number of seconds}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{5 seconds}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds;
    } else if (durationSeconds < secondsPerMinute * 1.5) { // 1 Minute
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_MINUTES_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of minutes}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5m' not '5 m'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SINGLE_MINUTE",
                @"{{1 minute}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{1 minute}}'. See other *_TIME_AMOUNT strings");
        }
        duration = durationSeconds / secondsPerMinute;
    } else if (durationSeconds < secondsPerHour) { // Multiple Minutes
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_MINUTES_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of minutes}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5m' not '5 m'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_MINUTES",
                @"{{number of minutes}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{5 minutes}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerMinute;
    } else if (durationSeconds < secondsPerHour * 1.5) { // 1 Hour
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_HOURS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of hours}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5h' not '5 h'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SINGLE_HOUR",
                @"{{1 hour}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{1 hour}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerHour;
    } else if (durationSeconds < secondsPerDay) { // Multiple Hours
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_HOURS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of hours}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5h' not '5 h'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_HOURS",
                @"{{number of hours}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{5 hours}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerHour;
    } else if (durationSeconds < secondsPerDay * 1.5) { // 1 Day
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_DAYS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of days}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5d' not '5 d'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SINGLE_DAY",
                @"{{1 day}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{1 day}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerDay;
    } else if (durationSeconds < secondsPerWeek) { // Multiple Days
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_DAYS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of days}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5d' not '5 d'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_DAYS",
                @"{{number of days}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{5 days}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerDay;
    } else if (durationSeconds < secondsPerWeek * 1.5) { // 1 Week
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_WEEKS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of weeks}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5w' not '5 w'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_SINGLE_WEEK",
                @"{{1 week}} embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{1 week}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerWeek;
    } else { // Multiple weeks
        if (useShortFormat) {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_WEEKS_SHORT_FORMAT",
                @"Label text below navbar button, embeds {{number of weeks}}. Must be very short, like 1 or 2 "
                @"characters, The space is intentionally omitted between the text and the embedded duration so that "
                @"we get, e.g. '5w' not '5 w'. See other *_TIME_AMOUNT strings");
        } else {
            amountFormat = OWSLocalizedString(@"TIME_AMOUNT_WEEKS",
                @"{{number of weeks}}, embedded in strings, e.g. 'Alice updated disappearing messages "
                @"expiration to {{5 weeks}}'. See other *_TIME_AMOUNT strings");
        }

        duration = durationSeconds / secondsPerWeek;
    }

    return [NSString stringWithFormat:amountFormat,
                     [NSNumberFormatter localizedStringFromNumber:@(duration) numberStyle:NSNumberFormatterNoStyle]];
}

- (NSString *)removeAllCharactersIn:(NSCharacterSet *)characterSet
{
    OWSAssertDebug(characterSet);

    return [[self componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
}

- (NSString *)digitsOnly
{
    return [self removeAllCharactersIn:[NSCharacterSet.decimalDigitCharacterSet invertedSet]];
}

@end

NS_ASSUME_NONNULL_END
