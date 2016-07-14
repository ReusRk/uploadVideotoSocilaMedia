//
//  MainViewController.h
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <MobileCoreServices/UTType.h>
#include <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <DropboxSDK/DropboxSDK.h>
#import "GTLDrive.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import <OneDriveSDK/OneDriveSDK.h>
#define CAPTURE_FRAMES_PER_SECOND		20

@interface MainViewController : UIViewController{
    
    BOOL isVideoFile;
    BOOL inBackground;
    BOOL mainFolder;
    BOOL datedFolder;
    
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *slideBarButton;
@property (nonatomic, retain) GTLServiceDrive *service;
@property (retain) AVCaptureVideoPreviewLayer *PreviewLayer;
@property (assign, nonatomic) UIBackgroundTaskIdentifier backgroundTaskID;


@end
