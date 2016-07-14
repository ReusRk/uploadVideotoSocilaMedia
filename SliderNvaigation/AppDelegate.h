//
//  AppDelegate.h
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <OneDriveSDK/OneDriveSDK.h>
#define DELEGATE ((AppDelegate*)[[UIApplication sharedApplication]delegate])
#define FACEBOOK_SCHEME @"fb1015182988558102"
#define db_APP_KEY   @"kg33z95c56d0s9z"
#define db_APP_SECRET   @"c000pbpzquadxj5"
static NSString *const kKeychainItemName = @"GDrive";
static NSString *const kClientID = @"895989665787-eu5jmgb66j0239mk2v36clon5khmi73g.apps.googleusercontent.com";
static NSString *const kClientSecret = @"1MPLKALPHp7jsysUz9BrQt8i";

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
 
    NSString *relinkUserId;

}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL hideScreen;
@property (nonatomic) BOOL recordingOnLaunch;

@end

