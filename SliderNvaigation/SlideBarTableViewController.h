//
//  SlideBarTableViewController.h
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OneDriveSDK/OneDriveSDK.h>
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <DropboxSDK/DropboxSDK.h>
#import "AppDelegate.h"
#import "SettingTableViewCell.h"
#import "SVProgressHUD.h"
#import <DropboxSDK/DropboxSDK.h>
@interface SlideBarTableViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, retain) GTLServiceDrive *service;
@property (strong, nonatomic) ODClient *client;
@property ODItem *currentItem;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskID;
@property (weak, nonatomic) IBOutlet UIButton *hiddenRecording;
@property (weak, nonatomic) IBOutlet UIButton *applauncgRecording;

@end
