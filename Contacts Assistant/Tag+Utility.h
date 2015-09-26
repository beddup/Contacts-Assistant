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

+(NSArray *)allTags;
+(NSArray *)allTagsSortedByOwnedContactsCountAndTagName;
-(BOOL)isRootTag;

-(NSArray *)allOwnedContacts;


+(Tag *)rootTag;
+(NSArray *)tagsWhoseNameContains:(NSString *)keyword;
+(void)deleteTag:(Tag *)tag;

+(BOOL)tagExists:(NSString *)tagName;
+(Tag *)createTagWithName:(NSString *)name; // if tag with the name exists , return the existing tag, if not, create it

@end
