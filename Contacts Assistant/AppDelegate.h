//
//  AppDelegate.h
//  Contacts Assistant
//
//  Created by Amay on 7/13/15.
//  Copyright (c) 2015 Beddup. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <MessageUI/MessageUI.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


@property (nonatomic, strong) MFMessageComposeViewController *globalMessageComposer;
@property (nonatomic, strong) MFMailComposeViewController *globalMailComposer;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
-(void)cycleTheGlobalMailComposer;
-(void)cycleTheGlobalMessageComposer;


@end

