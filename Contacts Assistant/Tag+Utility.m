//
//  Tag+Utility.m
//  
//
//  Created by Amay on 7/22/15.
//
//

#import "Tag+Utility.h"

@implementation Tag (Utility)

-(BOOL)isRootTag{
    return [self.tagName isEqualToString:@"RootTag"];
}

@end
