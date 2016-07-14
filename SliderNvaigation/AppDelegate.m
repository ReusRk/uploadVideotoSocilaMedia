//
//  AppDelegate.m
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import "AppDelegate.h"


@interface AppDelegate ()<DBSessionDelegate, DBNetworkRequestDelegate>

@end

@implementation AppDelegate
@synthesize hideScreen;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    hideScreen = [[NSUserDefaults standardUserDefaults] boolForKey:@"hideScreen"];

    
# pragma OneDriveSetup
    
    [ODClient setMicrosoftAccountAppId:@"000000004C114A26" scopes:@[@"onedrive.appfolder"] ];
    
#pragma DropBoxSetup
    
    DBSession *dbSession = [[DBSession alloc]
                            initWithAppKey:db_APP_KEY
                            appSecret:db_APP_SECRET
                            root:kDBRootAppFolder]; // either kDBRootAppFolder or kDBRootDropbox
    dbSession.delegate = self;
    [DBSession setSharedSession:dbSession];
    [DBRequest setNetworkRequestDelegate:self];
    
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    

    
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        if ([[DBSession sharedSession] isLinked]) {
            NSLog(@"App linked successfully!");
            // At this point you can start making API calls
        }
        return YES;
    }
    if ([[url scheme] isEqualToString:FACEBOOK_SCHEME])
        
    {
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    }
    
    return NO;
}


#pragma mark - DBSessionDelegate methods
- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session userId:(NSString *)userId
{
    relinkUserId = userId;
    [[[UIAlertView alloc] initWithTitle:@"Dropbox Session Ended" message:@"Do you want to relink?" delegate:self
                      cancelButtonTitle:@"Cancel" otherButtonTitles:@"Relink", nil] show];
}
#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index
{
    if (index != alertView.cancelButtonIndex) {
        [[DBSession sharedSession] linkFromController:_window.rootViewController];
    }
    relinkUserId = nil;
}
#pragma mark DBNetworkRequestDelegate methods
static int outstandingRequests;
- (void)networkRequestStarted
{
    outstandingRequests++;
    if (outstandingRequests == 1) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}
- (void)networkRequestStopped
{
    outstandingRequests--;
    if (outstandingRequests == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    application.applicationIconBadgeNumber = 0;
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
