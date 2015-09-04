//
//  NSString+ContactsAssistant.m
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "NSString+ContactsAssistant.h"

@implementation NSString (ContactsAssistant)
-(NSString *)firstLetterOfString{
    // first letter or pinyin
    if (!self.length) {
        return @"#";
    }
    NSMutableString *mString=[self mutableCopy];
    CFRange range=CFRangeMake(0, 1);
    CFStringTransform((__bridge CFMutableStringRef)mString, &range, kCFStringTransformMandarinLatin, NO);
    NSString *firstLetter=[[mString substringToIndex:1] uppercaseString];
    if ([firstLetter compare:@"A"] == NSOrderedAscending || [firstLetter compare:@"Z"] ==NSOrderedDescending) {
        // < @"A" || > @"Z"
        firstLetter=@"#";
    }
    return firstLetter;

}

@end
