//
//  Tag+Utility.m
//  
//
//  Created by Amay on 7/22/15.
//
//

#import "Tag+Utility.h"
#import "AppDelegate.h"

NSString * const RootTagName =@"RootTagName";

@implementation Tag (Utility)
-(BOOL)isRootTag{
    return [self.tagName isEqualToString:RootTagName];
}

-(NSArray *)allOwnedContacts{
    return nil;
}
+(Tag *)tagWithName:(NSString *)name{
    NSFetchRequest *fetchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
# warning upper case and lower case
    fetchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName == %@",name];
    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSArray *tags=[context executeFetchRequest:fetchRequest error:NULL];
    return  [tags firstObject];
}

+(Tag *)createTagWithTagName:(NSString *)name{

    Tag *tag=[Tag tagWithName:name];
    if (!tag) {
        NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
        tag=[NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:context];
        tag.tagName=name;
    }
    return tag;
}
+(Tag *)rootTag{
    return [Tag tagWithName:RootTagName];
}
+(NSArray *)tagsWhoseNameContains:(NSString *)keyword{
    //get possible tags
    NSManagedObjectContext *context=((AppDelegate *)[UIApplication sharedApplication].delegate).managedObjectContext;
    NSFetchRequest *tagFectchRequest=[NSFetchRequest fetchRequestWithEntityName:@"Tag"];
# warning upper case and lower case
    tagFectchRequest.predicate=[NSPredicate predicateWithFormat:@"tagName CONTAINS %@",keyword];
    NSArray *advicedtags=[context executeFetchRequest:tagFectchRequest error:NULL];
    return advicedtags;
}
@end
