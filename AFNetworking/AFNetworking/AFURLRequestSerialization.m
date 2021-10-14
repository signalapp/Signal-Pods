// AFURLRequestSerialization.m
// Copyright (c) 2011–2016 Alamofire Software Foundation ( http://alamofire.org/ )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFURLRequestSerialization.h"

#if TARGET_OS_IOS || TARGET_OS_WATCH || TARGET_OS_TV
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

NSString * const AFURLRequestSerializationErrorDomain = @"com.alamofire.error.serialization.request";

typedef NSString * (^AFQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError *__autoreleasing *error);

/**
 Returns a percent-escaped string following RFC 3986 for a query string key or value.
 RFC 3986 states that the following characters are "reserved" characters.
 - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
 - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
 
 In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
 query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
 should be percent-escaped in the query string.
 - parameter string: The string to be percent-escaped.
 - returns: The percent-escaped string.
 */
NSString * AFPercentEscapedStringFromString(NSString *string) {
    static NSString * const kAFCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kAFCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kAFCharactersGeneralDelimitersToEncode stringByAppendingString:kAFCharactersSubDelimitersToEncode]];
    
    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
        NSUInteger length = MIN(string.length - index, batchSize);
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

#pragma mark -

@interface AFQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)URLEncodedStringValue;
@end

@implementation AFQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.field = field;
    self.value = value;
    
    return self;
}

- (NSString *)URLEncodedStringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return AFPercentEscapedStringFromString([self.field description]);
    } else {
        return [NSString stringWithFormat:@"%@=%@", AFPercentEscapedStringFromString([self.field description]), AFPercentEscapedStringFromString([self.value description])];
    }
}

@end

#pragma mark -

FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary);
FOUNDATION_EXPORT NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value);

NSString * AFQueryStringFromParameters(NSDictionary *parameters) {
    NSMutableArray *mutablePairs = [NSMutableArray array];
    for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
        [mutablePairs addObject:[pair URLEncodedStringValue]];
    }
    
    return [mutablePairs componentsJoinedByString:@"&"];
}

NSArray * AFQueryStringPairsFromDictionary(NSDictionary *dictionary) {
    return AFQueryStringPairsFromKeyAndValue(nil, dictionary);
}

NSArray * AFQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when deserializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            if (nestedValue) {
                [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue((key ? [NSString stringWithFormat:@"%@[%@]", key, nestedKey] : nestedKey), nestedValue)];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        for (id nestedValue in array) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[]", key], nestedValue)];
        }
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:AFQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[AFQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}

#pragma mark -

@interface AFStreamDelegate : NSObject <NSStreamDelegate>

@property (atomic) BOOL hadError;

@end

#pragma mark -

@implementation AFStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode == NSStreamEventErrorOccurred) {
        self.hadError = YES;
    }
}

@end

#pragma mark -

@implementation AFMultipartTextPart

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value
{
    self = [super init];
    if (!self) {
        return self;
    }
    
    _key = key;
    _value = value;
    
    return self;
}

@end

#pragma mark -

static NSString * AFCreateMultipartFormBoundary() {
    return [NSString stringWithFormat:@"Boundary+%08X%08X", arc4random(), arc4random()];
}

static NSString * const kAFMultipartFormCRLF = @"\r\n";

static inline NSString * AFMultipartFormInitialBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"--%@%@", boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormEncapsulationBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}

static inline NSString * AFMultipartFormFinalBoundary(NSString *boundary) {
    return [NSString stringWithFormat:@"%@--%@--%@", kAFMultipartFormCRLF, boundary, kAFMultipartFormCRLF];
}

#pragma mark -

@implementation AFMultipartBody

+  (NSStringEncoding)stringEncoding {
    return NSUTF8StringEncoding;
}

+ (BOOL)writeMultipartBodyForInputFileURL:(NSURL *)inputFileURL
                            outputFileURL:(NSURL *)outputFileURL
                                     name:(NSString *)name
                                 fileName:(NSString *)fileName
                                 mimeType:(NSString *)mimeType
                                 boundary:(NSString *)boundary
                                textParts:(NSArray<AFMultipartTextPart *> *)textParts
                                    error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(inputFileURL);
    NSParameterAssert(outputFileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
    
    if (![outputFileURL isFileURL]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    
    // TODO: Audit streamStatus
    NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:outputFileURL append:NO];
    AFStreamDelegate *outputStreamDelegate = [AFStreamDelegate new];
    outputStream.delegate = outputStreamDelegate;
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream open];
    
    if (outputStream.streamStatus != NSStreamStatusOpen) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"File URL not reachable.", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    
    void (^closeOutputStream)(void) = ^{
        [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [outputStream close];
    };

    BOOL isFirstPart = YES;
    for (AFMultipartTextPart *textPart in textParts) {
        if (![self writeTextPartWithValue:textPart.value
                                     name:textPart.key
                                 boundary:boundary
                       hasInitialBoundary:isFirstPart
                         hasFinalBoundary:NO
                             outputStream:outputStream
                                    error:error]) {
            closeOutputStream();
            return NO;
        }
        isFirstPart = NO;
    }

    if (![self writeBodyPartWithInputFileURL:inputFileURL
                                        name:name
                                    fileName:fileName
                                    mimeType:mimeType
                                    boundary:boundary
                          hasInitialBoundary:isFirstPart
                            hasFinalBoundary:YES
                                outputStream:outputStream
                                       error:error]) {
        closeOutputStream();
        return NO;
    }

    closeOutputStream();

    if (outputStream.streamStatus != NSStreamStatusClosed || outputStreamDelegate.hadError) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
        }
        return NO;
    }
    
    return YES;
}

+ (NSString *)createMultipartFormBoundary
{
    return AFCreateMultipartFormBoundary();
}

+ (BOOL)writeBodyPartWithInputFileURL:(NSURL *)inputFileURL
                                 name:(NSString *)name
                             fileName:(NSString *)fileName
                             mimeType:(NSString *)mimeType
                             boundary:(NSString *)boundary
                   hasInitialBoundary:(BOOL)hasInitialBoundary
                     hasFinalBoundary:(BOOL)hasFinalBoundary
                         outputStream:(NSOutputStream *)outputStream
                                error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(inputFileURL);
    NSParameterAssert(name);
    NSParameterAssert(fileName);
    NSParameterAssert(mimeType);
        
    NSStringEncoding stringEncoding = self.stringEncoding;
    
    NSData *encapsulationBoundaryData = [(hasInitialBoundary
                                          ? AFMultipartFormInitialBoundary(boundary)
                                          : AFMultipartFormEncapsulationBoundary(boundary)) dataUsingEncoding:stringEncoding];
    if (![self writeData:encapsulationBoundaryData outputStream:outputStream error:error]) {
        return NO;
    }
    
    NSDictionary *headers = [self headersForBodyWithName:name
                                                fileName:fileName
                                                mimeType:mimeType];
    NSString *headersString = [self stringForHeaders:headers];
    NSData *headersData = [headersString dataUsingEncoding:stringEncoding];
    if (![self writeData:headersData outputStream:outputStream error:error]) {
        return NO;
    }
    
    if (![self writeInputFileURL:inputFileURL outputStream:outputStream error:error]) {
        return NO;
    }
    
    NSData *closingBoundaryData = (hasFinalBoundary
                                   ? [AFMultipartFormFinalBoundary(boundary) dataUsingEncoding:stringEncoding]
                                   : [NSData data]);
    if (![self writeData:closingBoundaryData outputStream:outputStream error:error]) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)writeInputFileURL:(NSURL *)inputFileURL
             outputStream:(NSOutputStream *)outputStream
                    error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(inputFileURL);
    
    if (![inputFileURL isFileURL]) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"Expected URL to be a file URL", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    } else if ([inputFileURL checkResourceIsReachableAndReturnError:error] == NO) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"File URL not reachable.", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    
    NSDictionary *inputFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[inputFileURL path] error:error];
    if (!inputFileAttributes) {
        return NO;
    }
    
    NSInputStream *inputStream = [NSInputStream inputStreamWithURL:inputFileURL];
    AFStreamDelegate *inputStreamDelegate = [AFStreamDelegate new];
    inputStream.delegate = inputStreamDelegate;
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [inputStream open];
    if (inputStream.streamStatus != NSStreamStatusOpen) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"File URL not reachable.", @"AFNetworking", nil)};
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:userInfo];
        }
        return NO;
    }
    
    void (^closeInputStream)(void) = ^{
        [inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [inputStream close];
    };
    
    if (![self writeBodyInputStream:inputStream
                       outputStream:outputStream
                              error:error]) {
        closeInputStream();
        return NO;
    }
    
    closeInputStream();
    
    if (inputStream.streamStatus != NSStreamStatusClosed || inputStreamDelegate.hadError) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
        }
        return NO;
    }
    
    return YES;
}

+ (BOOL)writeTextPartWithValue:(NSString *)value
                          name:(NSString *)name
                      boundary:(NSString *)boundary
            hasInitialBoundary:(BOOL)hasInitialBoundary
              hasFinalBoundary:(BOOL)hasFinalBoundary
                  outputStream:(NSOutputStream *)outputStream
                         error:(NSError * __autoreleasing *)error
{
    NSParameterAssert(value.length > 0);
    NSParameterAssert(name.length > 0);

    NSStringEncoding stringEncoding = self.stringEncoding;
    
    NSData *encapsulationBoundaryData = [(hasInitialBoundary
                                          ? AFMultipartFormInitialBoundary(boundary)
                                          : AFMultipartFormEncapsulationBoundary(boundary)) dataUsingEncoding:stringEncoding];
    if (![self writeData:encapsulationBoundaryData outputStream:outputStream error:error]) {
        return NO;
    }
    
    NSMutableDictionary<NSString *, NSString *> *headers = [NSMutableDictionary new];
    [headers setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"", name] forKey:@"Content-Disposition"];
    NSString *headersString = [self stringForHeaders:headers];
    NSData *headersData = [headersString dataUsingEncoding:stringEncoding];
    if (![self writeData:headersData outputStream:outputStream error:error]) {
        return NO;
    }

    NSData *valueData = [value dataUsingEncoding:stringEncoding];
    if (![self writeData:valueData outputStream:outputStream error:error]) {
        return NO;
    }
    
    NSData *closingBoundaryData = (hasFinalBoundary
                                   ? [AFMultipartFormFinalBoundary(boundary) dataUsingEncoding:stringEncoding]
                                   : [NSData data]);
    if (![self writeData:closingBoundaryData outputStream:outputStream error:error]) {
        return NO;
    }
    
    return YES;
}

+ (BOOL)writeBodyInputStream:(NSInputStream *)inputStream
                outputStream:(NSOutputStream *)outputStream
                       error:(NSError * __autoreleasing *)error
{
    NSInteger bufferSize = 16 * 1024;
    uint8_t buffer[bufferSize];
    
    NSInteger totalBytesReadCount = 0;
    while ([inputStream hasBytesAvailable]) {
        if (![outputStream hasSpaceAvailable]) {
            if (error) {
                *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
            }
            return NO;
        }
        
        NSInteger numberOfBytesRead = [inputStream read:buffer maxLength:bufferSize];
        if (numberOfBytesRead < 0) {
            if (error) {
                *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
            }
            return NO;
        }
        if (numberOfBytesRead == 0) {
            return YES;
        }
        totalBytesReadCount += numberOfBytesRead;
        
        NSInteger totalBytesWrittenCount = 0;
        while (totalBytesWrittenCount < numberOfBytesRead) {
            NSInteger writeSize = numberOfBytesRead - totalBytesWrittenCount;
            NSInteger bytesWrittenCount = [outputStream write:&buffer[totalBytesWrittenCount] maxLength:writeSize];
            if (bytesWrittenCount < 1) {
                *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
                return NO;
            }
            totalBytesWrittenCount += bytesWrittenCount;
        }
    }
    return YES;
}

+ (BOOL)writeData:(NSData *)data
     outputStream:(NSOutputStream *)outputStream
            error:(NSError * __autoreleasing *)error
{
    NSInteger totalBytesCount = data.length;
    NSInteger bufferSize = 16 * 1024;
    uint8_t buffer[bufferSize];
    
    NSInteger totalBytesWrittenCount = 0;
    while (totalBytesWrittenCount < totalBytesCount) {
        NSInteger blockSize = MIN((totalBytesCount - totalBytesWrittenCount), bufferSize);
        NSRange range = NSMakeRange((NSUInteger)totalBytesWrittenCount, blockSize);
        [data getBytes:buffer range:range];
        NSInteger bytesWrittenCount = [outputStream write:buffer maxLength:blockSize];
        if (bytesWrittenCount < 1) {
            *error = [[NSError alloc] initWithDomain:AFURLRequestSerializationErrorDomain code:NSURLErrorBadURL userInfo:nil];
            return NO;
        }
        totalBytesWrittenCount += bytesWrittenCount;
    }
    return YES;
}

+ (NSDictionary *)headersForBodyWithName:(NSString *)name
                                fileName:(NSString *)fileName
                                mimeType:(NSString *)mimeType
{
    NSMutableDictionary *mutableHeaders = [NSMutableDictionary dictionary];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; filename=\"%@\"", name, fileName] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    return mutableHeaders;
}

+ (NSString *)stringForHeaders:(NSDictionary *)headers {
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *field in [headers allKeys]) {
        [headerString appendString:[NSString stringWithFormat:@"%@: %@%@",
                                    field,
                                    [headers valueForKey:field],
                                    kAFMultipartFormCRLF]];
    }
    [headerString appendString:kAFMultipartFormCRLF];
    return [NSString stringWithString:headerString];
}

@end
