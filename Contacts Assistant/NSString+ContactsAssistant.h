//
//  NSString+ContactsAssistant.h
//  Contacts Assistant
//
//  Created by Amay on 8/31/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (ContactsAssistant)
-(NSString *)firstLetterOfString;  // first letter or pinyin
-(NSString *)whiteSpaceAtEndsTrimmedString; // trim the white space front and behind
-(NSString *)whiteSpaceAtEndsAndNewLinsTrimmedString; // trim the white space front and behind
-(NSInteger)whiteSpaceTrimmedLength;

//event
+(NSString *)repeatedDaySymbols:(NSArray *)repeatedDays;
@end
