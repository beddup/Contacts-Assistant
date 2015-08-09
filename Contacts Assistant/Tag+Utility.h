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
-(NSInteger)numberOfAllOwnedContacts;

+(Tag *)rootTag;
+(NSArray *)tagsWhoseNameContains:(NSString *)keyword;
+(NSArray *)allTags;
+(void)deleteTag:(Tag *)tag;

+(BOOL)tagExists:(NSString *)tagName;
+(Tag *)getTagWithTagName:(NSString *)name; // if tag exists , return the existing tag, if not, create it

@end
