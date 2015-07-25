//
//  Tag+Utility.h
//  
//
//  Created by Amay on 7/22/15.
//
//

#import "Tag.h"
extern NSString * const RootTagName ;

@interface Tag (Utility)
-(BOOL)isRootTag;
-(NSArray *)allOwnedContacts;
+(Tag *)tagWithName:(NSString *)name;
+(Tag *)createTagWithTagName:(NSString *)name;
+(Tag *)rootTag;
+(NSArray *)tagsWhoseNameContains:(NSString *)keyword;

@end
