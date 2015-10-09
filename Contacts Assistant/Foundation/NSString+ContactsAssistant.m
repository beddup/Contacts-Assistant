//
//  NSString+ContactsAssistant.m
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import "NSString+ContactsAssistant.h"
#import "pinyin.h"
@implementation NSString (ContactsAssistant)
-(NSString *)firstLetterOfString{
    // first letter or pinyin
    if (!self.length) {
        return @"#";
    }

    NSString *firstLetter=[[self substringWithRange:NSMakeRange(0, 1)] uppercaseString];

    if ([firstLetter compare:@"A"] == NSOrderedDescending &&
        [firstLetter compare:@"Z"] == NSOrderedAscending) {
        // if not 汉字， 默认为英语
        return firstLetter;
    }

    char c =pinyinFirstLetter([self characterAtIndex:0]);
    char cString[2]={c,'\0'};
    firstLetter=[NSString stringWithCString:cString encoding: NSStringEncodingConversionExternalRepresentation];

    // only 400ms
    return [firstLetter uppercaseString];

//用一下方法也可以获得汉字的首字母，但是耗时，不推荐
//    NSMutableString *mString=[self mutableCopy];
//    CFRange range=CFRangeMake(0, 1);
//    CFStringTransform((__bridge CFMutableStringRef)mString, &range, kCFStringTransformMandarinLatin, NO);// 有声调，慢 1600ms
//    NSString *firstLetter=[[mString substringToIndex:1] uppercaseString];
//    if ([firstLetter compare:@"A"] == NSOrderedAscending || [firstLetter compare:@"Z"] ==NSOrderedDescending) {
//        firstLetter=@"#";
//    }
//    return firstLetter;

}
-(NSString *)whiteSpaceAtEndsTrimmedString{
    // trim the white space front and behind
    NSCharacterSet *whiteSpace=[NSCharacterSet whitespaceCharacterSet];
    return [self stringByTrimmingCharactersInSet:whiteSpace];
}

-(NSString *)whiteSpaceAtEndsAndNewLinsTrimmedString{
    NSCharacterSet *whiteSpace=[NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [self stringByTrimmingCharactersInSet:whiteSpace];

}

-(NSInteger)whiteSpaceTrimmedLength{
    return [[self whiteSpaceAtEndsTrimmedString] length];
}

+(NSString *)repeatedDaySymbols:(NSArray *)repeatedDays{
    if (repeatedDays.count == 0) {
        return nil;
    }
    if (repeatedDays.count == 7) {
        return @"每天";
    }

    NSArray *weekSymbols=[[NSCalendar currentCalendar]weekdaySymbols];
    NSMutableArray *symbols=[@[] mutableCopy];
    for (NSNumber * index in repeatedDays) {
        [symbols addObject:weekSymbols[index.integerValue-1]];
    }
    return [symbols componentsJoinedByString:@","];
}

@end
