//
//  Tag+Utility.m
//  
//
//  Created by Amay on 7/22/15.
//
//

#import "Tag+Utility.h"
#import "AppDelegate.h"

NSString * const RootTagName =@"所有联系人";

@implementation Tag (Utility)
-(BOOL)isRootTag{
    return [self.tagName isEqualToString:RootTagName];
}

-(NSArray *)allOwnedContacts{
    return [[self.ownedContacts allObjects] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"contactIsDeleted.boolValue == %d",NO]];
}

+(Tag *)tagWithName:(NSString *)name{
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName MATCHES[c] %@",name];
    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSArray *tags=[context executeFetchRequest:fetchRequest error:NULL];
    return  [tags firstObject];
}

+(Tag *)createTagWithName:(NSString *)name{
    Tag *tag=[Tag tagWithName:name];
    if (!tag) {
        NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
        tag=[NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
        tag.tagName=name;
    }
    return tag;

}
+(Tag *)rootTag{
    return [self createTagWithName:RootTagName];
}

+(BOOL)tagExists:(NSString *)tagName{

    if ([self tagWithName:tagName]){
        return YES;
    }
    return NO;
}

+(NSArray *)tagsWhoseNameContains:(NSString *)keyword{
    //get possible tags
    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *tagFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    tagFectchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName CONTAINS[c] %@",keyword];
    NSArray *advicedtags=[context executeFetchRequest:tagFectchRequest error:NULL];
    return advicedtags;
}
+(NSArray *)allTags{

    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;

    NSFetchRequest *tagFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    NSMutableArray *advicedtags=[[context executeFetchRequest:tagFectchRequest error:NULL] mutableCopy];

    return advicedtags;

}
+(NSArray *)allTagsSortedByOwnedContactsCountAndTagName{
    return [[Tag allTags] sortedArrayUsingComparator:^NSComparisonResult(Tag * obj1, Tag * obj2) {
                NSInteger obj1Count=obj1.ownedContacts.count;
                NSInteger obj2Count=obj2.ownedContacts.count;
                if (obj1Count == obj2Count) {
                    return [obj1.tagName compare:obj2.tagName];
                }
                return obj1Count < obj2Count;
            }];
}
+(void)deleteTag:(Tag *)tag{
    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    [context deleteObject:tag];
}

@end
