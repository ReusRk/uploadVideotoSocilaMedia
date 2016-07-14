//
//  MainViewController.m
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"

@interface MainViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,DBRestClientDelegate>{
    
    BOOL WeAreRecording;
    AVCaptureSession *CaptureSession;
    AVCaptureMovieFileOutput *MovieFileOutput;
    AVCaptureDeviceInput *VideoInputDevice;
    UIView *CameraView;
    UIView *blackview;
    UILabel *labelTime;
    UITapGestureRecognizer  *recordGestureRecognizer,*stoprecordGestureRecognizer;
    UIImagePickerController *camera;
    NSInteger part;
    UIButton *stopBtn;
    BOOL videoRecording;
    BOOL partlyRecording;
    BOOL videoSessionInProgress;
    NSOperationQueue *queue;
}

@property (nonatomic, strong) DBRestClient *restClient;

@property (nonatomic, retain) GTLServiceDrive *driveService;
@property (nonatomic) GTLDriveParentReference *parentRef;
@property (nonatomic) NSInteger timeInSeconds;
@property (nonatomic) NSTimer *timer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (strong, nonatomic) ODClient *client;
@property ODItem *currentItem;

@end

@implementation MainViewController
@synthesize PreviewLayer;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Upload";
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if ( revealViewController )
    {
        [self.slideBarButton setTarget: self.revealViewController];
        [self.slideBarButton setAction: @selector( revealToggle: )];
        [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    }
    
    partlyRecording = NO;
    
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                         clientID:kClientID
                                                                                     clientSecret:kClientSecret];
    
    queue = [[NSOperationQueue alloc]init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    // Getting One Drive Client...
    
    NSLog(@"CurrentClient : %@",[ODClient loadCurrentClient]);
    self.client = [ODClient loadCurrentClient];
    
    // Getting GoogleDrive Autho
    self.driveService = [[GTLServiceDrive alloc] init];
    self.driveService.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                         clientID:kClientID
                                                                                     clientSecret:kClientSecret];
}


#pragma Upload Video

- (IBAction)uploadVideo:(id)sender {
    
    if (self.client || [[DBSession sharedSession] isLinked] || self.driveService.authorizer.canAuthorize || [FBSDKAccessToken currentAccessToken]) {
        [self setUpCamera];
    }else{
        
        UIAlertView *alert;
        alert = [[UIAlertView alloc] initWithTitle: @"Alert"
                                           message: @"First login with account to upload video!"
                                          delegate: nil
                                 cancelButtonTitle: @"OK"
                                 otherButtonTitles: nil];
        [alert show];
    }
    
}

#pragma Camera Setup

-(void)setUpCamera{
    
    camera = [[UIImagePickerController alloc] init];
    camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    camera.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, nil];
    camera.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    camera.showsCameraControls = NO;
    camera.cameraViewTransform = CGAffineTransformIdentity;
    camera.cameraOverlayView = [self customCameraOverlay];
    
    camera.videoQuality = UIImagePickerControllerQualityTypeLow;
    
    camera.delegate = self;
    camera.edgesForExtendedLayout = UIRectEdgeAll;
    [self presentViewController:camera animated:YES completion:nil];
}

-(UIView *)customCameraOverlay
{
    UIView *customCameraOverlayView = [[UIView alloc]initWithFrame:self.view.frame];
    [customCameraOverlayView setBackgroundColor:[UIColor clearColor]];
    
    if ([DELEGATE hideScreen]) {
        [customCameraOverlayView setBackgroundColor:[UIColor blackColor]];
        
    }
    //    stopBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width / 2 - 38, self.view.frame.size.height - 100, 80, 80)];
    //    [stopBtn setBackgroundImage:[UIImage imageNamed:@"Button-2-stop-icon.png"] forState:UIControlStateNormal];
    //    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    //    [stopBtn setHidden:YES];
    //    [customCameraOverlayView addSubview:stopBtn];
    recordGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(beginVideoRecordingSession)];
    
    recordGestureRecognizer.numberOfTapsRequired = 2;
    
    [customCameraOverlayView addGestureRecognizer:recordGestureRecognizer];
    
    stoprecordGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapStop)];
    stoprecordGestureRecognizer.numberOfTapsRequired = 1;
    [customCameraOverlayView addGestureRecognizer:stoprecordGestureRecognizer];
    
    return customCameraOverlayView;
}

#pragma mark - Recording Timer

-(void)startRecordingTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.timer invalidate];
        self.timer = nil;
        
        self.timer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        
        NSDate *timerTimeStamp = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setValue:timerTimeStamp forKey:@"startTimeStamp"];
        
    });
    
}

-(void)fireTimer: (NSTimer *) timer
{
    NSDate *startTime = [[NSUserDefaults standardUserDefaults] valueForKey:@"startTimeStamp"];
    NSTimeInterval stopTimeInterval = 5.0;
    NSTimeInterval currentTimeInterval = [[NSDate date] timeIntervalSinceDate:startTime];
    
    //For debugging only
    self.timeInSeconds += 1;
    
    if (currentTimeInterval >= stopTimeInterval) {
        partlyRecording = YES;
        part ++ ;
        [self stopVideoRecording];
        // [self performSelector:@selector(stopVideoRecording) withObject:self afterDelay:5.0];
        
    }
    
    NSLog(@"Timer Fired, time in seconds: %ld", (long)self.timeInSeconds);
}

-(void)singleTapStop{
    
    [self stop];
    
}

-(void)stop{
    
    videoSessionInProgress = NO;
    part++;
    if (!partlyRecording) {
        part = 0;
    }
    
    [self stopVideoRecording];}


- (void)stopVideoRecording
{
    if (videoRecording) {
        
        [self resetTimer];
        
        videoRecording = NO;
        //  videoSessionInProgress = NO;
        [camera stopVideoCapture];
        
        NSLog(@"Video recording: %@", (videoRecording ? @"YES" : @"NO"));
    }
    
}

-(void)resetTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.timer){
            
            [self.timer invalidate];
            self.timer = nil;
            
            self.timeInSeconds = 0;
            
            NSLog(@"Timer reset");
        }
    });
}

- (void)beginVideoRecordingSession
{
    videoSessionInProgress = YES;
    
    [self startVideoRecording];
    [stopBtn setHidden:NO];
    NSLog(@"video recording started");
    
    
}

- (void)startVideoRecording
{
    void (^hideControls)(void);
    hideControls = ^(void) {
        
    };
    
    void (^recordMovie)(BOOL finished);
    recordMovie = ^(BOOL finished) {
        
        videoRecording = YES;
        [camera startVideoCapture];
        [self startRecordingTimer];
    };
    
    // Hide controls
    [UIView  animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:hideControls completion:recordMovie];
    
}


#pragma Uploading and Video Picking


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    
    if (CFStringCompare ((__bridge CFStringRef) mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        NSURL *videoUrl = (NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
        NSString *videoPath = [videoUrl path];
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (videoPath)) {
            
            if (self.client) {
                
                [self uploadToOneDrive:videoPath];
                
            }else if ([[DBSession sharedSession] isLinked]){
                
                [self uploadToDropBox:videoPath];
                
            }else if (self.driveService.authorizer.canAuthorize){
                
                [self uploadToGoogleDriveInDatedFolder:videoPath];
                
            }else if ([FBSDKAccessToken currentAccessToken]){
                
                [self uploadToFacebook:videoPath];
            }
            
            
            
        } else {
            
            [self video:videoPath didFinishSavingWithError:nil contextInfo:NULL];
        }
        
    }
    
    if (videoSessionInProgress) {
        
        //[self didChangeCamera];
        videoRecording = YES;
        [camera startVideoCapture];
        [self startRecordingTimer];
        
        
        
        NSLog(@"Uploading in background and recording continued...");
        
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (!videoSessionInProgress) {
        
        // [self showCameraControls];
    }
    
}


#pragma Uploading to DropBox..

-(void)uploadToDropBox:(NSString *)videoPath{
    
    self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    self.restClient.delegate = self;
    if (![[DBSession sharedSession] isLinked]) {
    }else{
        if ([[UIDevice currentDevice] isMultitaskingSupported]){
            
            _backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                NSLog(@"Expiration handler called %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                _backgroundTaskID = 0;
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                
            }];}
        NSLog(@"Uploding Start");
        NSDateFormatter *dateform = [[NSDateFormatter alloc]init];
        [dateform setDateFormat:@"EEEE MMMM d YYYY h:mm a zzz"];
        NSDateFormatter *dateform1 = [[NSDateFormatter alloc]init];
        [dateform1 setDateFormat:@"EEEE MMMM dd YYYY h:mm a "];
        
        NSString *date = [dateform stringFromDate:[NSDate date]];
        NSString *filename;
        
        filename = [NSString stringWithFormat:@"iSting_%@.Mov", date];
        
        if (part > 0) {
            
            filename = [NSString stringWithFormat:@"iSting_%@ Part-%ld.Mov", [dateform1 stringFromDate:[NSDate date]],(long)part];
            
        }
        // NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), @"output.mov"];
        
        //   NSString *localPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mov"];
        NSString *destDir = @"/";
        [self.restClient uploadFile:filename toPath:destDir withParentRev:nil fromPath:videoPath];
        
        
    }
    
    
    
}


- (void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath
              from:(NSString *)srcPath metadata:(DBMetadata *)metadata {
    
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    
    if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
        _backgroundTaskID = 0;
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
        _backgroundTaskID = UIBackgroundTaskInvalid;
        [self presentNotification:@"DropBox VideoUpload Sucess"];
    }
    
    
    
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: @"Success"
                                       message: @"File Uploaded Successfully!"
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
    
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}

- (void)restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error {
    
    NSLog(@"File Not uploaded successfully: %@", error);
    _backgroundTaskID = 0;
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
        _backgroundTaskID = 0;
        [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
        _backgroundTaskID = UIBackgroundTaskInvalid;
        [self presentNotification:@"DropBox VideoUpload Failed"];
    }
}




#pragma Uploading to OneDrive..

-(void)uploadToOneDrive:(NSString *)videoPath{
    
    
    
    //   [queue addOperationWithBlock:^{
    
    
    NSDateFormatter *dateform = [[NSDateFormatter alloc]init];
    [dateform setDateFormat:@"EEEE MMMM d YYYY h mm a zzz"];
    NSDateFormatter *dateform1 = [[NSDateFormatter alloc]init];
    [dateform1 setDateFormat:@"EEEE MMMM d YYYY h mm a"];
    
    NSString *date = [dateform stringFromDate:[NSDate date]];
    NSString *filename;
    
    filename = [NSString stringWithFormat:@"iSting_%@.Mov", date];
    
    if (part > 0) {
        
        filename = [NSString stringWithFormat:@"iSting_%@ Part-%ld.Mov", [dateform1 stringFromDate:[NSDate date]],(long)part];
        
    }
    
    ODItem *imageFile = [[ODItem alloc] init];
    imageFile.name = filename;
    NSData *data = [NSData dataWithContentsOfFile:videoPath];
    
    NSLog(@"File size is : %.2f MB",(float)data.length/1024.0f/1024.0f);
    if ([[UIDevice currentDevice] isMultitaskingSupported]){
        
        _backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"Expiration handler called %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
            _backgroundTask = 0;
            [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
            
        }];}
    
    
    ODItemContentRequest *request = [[[[self.client drive] special:@"approot"] itemByPath:filename] contentRequest];
    
    ODURLSessionUploadTask *task = [request uploadFromData:data completion:^(ODItem *item, NSError *error){
        //  [self.progressController hideProgress];
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        
        // Returns the item that was just uploaded.
        if (!error) {
                if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
                _backgroundTask = 0;
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
                _backgroundTask = UIBackgroundTaskInvalid;
                //  [self presentNotification:@"OneDrive VideoUpload Sucess"];
            }
            //                    UIAlertView *alert;
            //                    alert = [[UIAlertView alloc] initWithTitle: @"Success"
            //                                                       message: @"Video Uploaded Successfully!"
            //                                                      delegate: nil
            //                                             cancelButtonTitle: @"OK"
            //                                             otherButtonTitles: nil];
            //                    [alert show];
            
            
            NSLog(@"itemUploaded : %@",item);
        }else{
            if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
                _backgroundTask = 0;
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTask];
                _backgroundTask = UIBackgroundTaskInvalid;
                // [self presentNotification:@"OneDrive VideoUpload Failed"];
            }
          
            //    [[ODAppConfiguration defaultConfiguration].logger setLogLevel:ODLogVerbose];
            NSLog(@"Error getting while uploading : %@",error);
            //  UIAlertView *alert;
            //                    alert = [[UIAlertView alloc] initWithTitle: @"Success"
            //                                                       message: @"Video Uploaded Failed!"
            //                                                      delegate: nil
            //                                             cancelButtonTitle: @"OK"
            //                                             otherButtonTitles: nil];
            //                    [alert show];
            
        }
        
    }];
    task.progress.totalUnitCount = (float)data.length/1024.0f/1024.0f;
    
    
    
}


#pragma Uploading to GoogleDrive..


-(void)uploadToGoogleDriveInDatedFolder: (NSString *)filePath
{
    [self searchForMainBMLPFolder:^(BOOL finished) {
        
        if (finished) {
            
            if (!mainFolder) {
                
                [self createMainBMLPfolder:^(GTLDriveParentReference *identifier) {
                    
                    [self createNewDatedFolderWithParentRef:identifier completion:^(GTLDriveParentReference *identifier) {
                        
                        // if (isVideoFile) {
                        
                        [self uploadVideo:filePath WithParentRef:identifier];
                        
                        //  }else {
                        
                        // [self uploadAudio:filePath WithParentRef:identifier];
                        //   }
                        
                        
                    }];
                    
                }];
                
            }else {
                
                [self searchForDatedFolder:^(BOOL finished) {
                    
                    if (finished) {
                        
                        if (!datedFolder) {
                            
                            [self createNewDatedFolderWithParentRef:self.parentRef completion:^(GTLDriveParentReference *identifier) {
                                
                                //                                if (isVideoFile) {
                                
                                [self uploadVideo:filePath WithParentRef:identifier];
                                
                                //  }else {
                                
                                //  [self uploadAudio:filePath WithParentRef:identifier];
                                //  }
                                
                            }];
                            
                        } else {
                            
                            //  if (isVideoFile) {
                            
                            [self uploadVideo:filePath WithParentRef:self.parentRef];
                            
                            //  }else {
                            
                            // [self uploadAudio:filePath WithParentRef:self.parentRef];
                            //  }
                            
                        }
                        
                    }
                    
                }];
                
            }
            
        }
    }];
    
    
}

//Check if a main BMLP folder has been created
typedef void(^completion)(BOOL);

- (void)searchForMainBMLPFolder:(completion) compblock
{
    NSString *parentId = @"root";
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' in parents and trashed=false", parentId];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFileList *fileList,
                                                              NSError *error) {
        if (error == nil) {
            NSLog(@"Have results");
            
            // Iterate over fileList.items array
            [self folder: @"iStingDemo" FoundInFileList:fileList.items Completion:^(bool folderFound) {
                
                mainFolder = folderFound;
                
                compblock(YES);
            }];
            
        } else {
            
            NSLog(@"An error occurred: %@", error);
            compblock(YES);
        }
        
    }];
}

//Check if dated folder has been created
- (void)searchForDatedFolder:(completion) compblock
{
    NSString *parentId = self.parentRef.identifier;
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' in parents and trashed=false", parentId];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFileList *fileList,
                                                              NSError *error) {
        if (error == nil) {
            NSLog(@"Have results");
            
            // Iterate over fileList.items array
            [self folder:[self datedFolderDateString] FoundInFileList:fileList.items Completion:^(bool folderFound) {
                
                datedFolder = folderFound;
                compblock(YES);
            }];
            
        } else {
            
            NSLog(@"An error occurred: %@", error);
            compblock(YES);
        }
        
    }];
}

//Check for folder and set self.parentRef if found
- (void)folder: (NSString *)folderTitle FoundInFileList: (NSArray *)items Completion: (void (^)(bool folderFound))handler
{
    BOOL found = NO;
    GTLDriveParentReference *parentRef = [GTLDriveParentReference object];
    
    for (GTLDriveFile *item in items) {
        
        if ([item.title isEqualToString:folderTitle]) {
            
            found = YES;
            parentRef.identifier = item.identifier;
            self.parentRef = parentRef;
        }
    }
    
    handler(found);
}

//Create main folder in Google Drive for BMLP files
- (void)createMainBMLPfolder:(void (^)(GTLDriveParentReference *identifier))handler
{
    GTLDriveFile *folder = [GTLDriveFile object];
    folder.title = @"iStingDemo";
    folder.mimeType = @"application/vnd.google-apps.folder";
    GTLDriveParentReference *parentRef = [GTLDriveParentReference object];
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:folder uploadParameters:nil];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFile *updatedFile,
                                                              NSError *error) {
        if (error == nil) {
            NSLog(@"Created main iSting files folder");
            mainFolder = YES;
            parentRef.identifier = updatedFile.identifier; // identifier property of the folder
            
        } else {
            NSLog(@"An error occurred: %@", error);
        }
        
        handler(parentRef);
    }];
    
}



//Create a new folder inside the main folder for each date
- (GTLDriveFile *)createNewDatedFolderWithParentRef: (GTLDriveParentReference *)mainFolderParentRef completion: (void (^)(GTLDriveParentReference *identifier))handler
{
    GTLDriveFile *folder = [GTLDriveFile object];
    folder.title = [self datedFolderDateString];
    folder.mimeType = @"application/vnd.google-apps.folder";
    folder.parents = @[mainFolderParentRef];
    
    GTLDriveParentReference *newFolderParentRef = [GTLDriveParentReference object];
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:folder uploadParameters:nil];
    [self.driveService executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                              GTLDriveFile *updatedFile,
                                                              NSError *error) {
        if (error == nil) {
            
            NSLog(@"Created new dated folder");
            datedFolder = YES;
            newFolderParentRef.identifier = updatedFile.identifier; // identifier property of the folder
            
        } else {
            
            NSLog(@"An error occurred: %@", error);
        }
        
        handler(newFolderParentRef);
    }];
    
    return folder;
}


//date formatter helper method
- (NSString *)datedFolderDateString
{
    // return a formatted string for a file name
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    return [dateFormat stringFromDate:[NSDate date]];
}


- (void)uploadVideo:(NSString *)videoURLPath WithParentRef: (GTLDriveParentReference *)parentRef
{
    
    NSDateFormatter *dateform = [[NSDateFormatter alloc]init];
    [dateform setDateFormat:@"EEEE MMMM d YYYY h:mm a zzz"];
    NSDateFormatter *dateform1 = [[NSDateFormatter alloc]init];
    [dateform1 setDateFormat:@"EEEE MMMM dd YYYY h:mm a"];
    
    NSString *date = [dateform stringFromDate:[NSDate date]];
    
    GTLDriveFile *file = [GTLDriveFile object];
    file.title = [NSString stringWithFormat:@"iSting_%@.Mov", date];
    
    if (part > 0) {
        
        file.title = [NSString stringWithFormat:@"iSting_%@ Part-%ld.Mov", [dateform1 stringFromDate:[NSDate date]],(long)part];
        
    }
    
    
    file.descriptionProperty = @"Uploaded from IOS iString App";
    file.mimeType = @"video/quicktime";
    file.fileExtension=@"MOV";
    file.kind=@"QuickTime movie";
    file.parents = @[parentRef];
    NSError *error = nil;
    
    NSData *data = [NSData dataWithContentsOfFile:videoURLPath options:NSDataReadingMappedIfSafe error:&error];
    
    GTLUploadParameters *uploadParameters = [GTLUploadParameters uploadParametersWithData:data MIMEType:file.mimeType];
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesInsertWithObject:file
                                                       uploadParameters:uploadParameters];
    
    
    //create animation
    // CABasicAnimation *animation = [self animateOpacity];
    
    //animation will start immediately
    
    [self.driveService executeQuery:query
                  completionHandler:^(GTLServiceTicket *ticket,
                                      GTLDriveFile *insertedFile, NSError *error) {
                      
                      
                      if (error == nil){
                          
                          NSLog(@"File ID: %@", insertedFile.identifier);
                          
                          //                          [self.customCameraOverlayView.uploadingLabel.layer removeAllAnimations];
                          //                          self.customCameraOverlayView.uploadingLabel.alpha = 0.0;
                          //
                          //                          [self fadeInFadeOutInfoLabel:self.customCameraOverlayView.fileSavedLabel WithMessage:@"File Saved"];
                          
                          
                      }else {
                          
                          NSLog(@"An error occurred: %@", error);
                          
                          //                          [self.customCameraOverlayView.uploadingLabel.layer removeAllAnimations];
                          //                          self.customCameraOverlayView.uploadingLabel.alpha = 0.0;
                          //
                          //                          [self fadeInFadeOutInfoLabel:self.customCameraOverlayView.fileSavedLabel WithMessage:@"Sorry an error occurred."];
                          
                      }
                  }];
}



#pragma Uploading to Facebook..


-(void)uploadToFacebook:(NSString *)videoPath{
    
    // NSData *data = [NSData dataWithContentsOfURL:videoURL options:NSDataReadingMappedAlways error:nil];
    NSData *data = [NSData dataWithContentsOfFile:videoPath];
    NSLog(@"File size is : %.2f MB",(float)data.length/1024.0f/1024.0f);
    NSDateFormatter *dateform = [[NSDateFormatter alloc]init];
    [dateform setDateFormat:@"EEEE MMMM d YYYY h:mm a zzz"];
    NSDateFormatter *dateform1 = [[NSDateFormatter alloc]init];
    [dateform1 setDateFormat:@"EEEE MMMM d YYYY h:mm a"];
    
    NSString *date = [dateform stringFromDate:[NSDate date]];
    NSString *filename;
    
    filename = [NSString stringWithFormat:@"iSting_%@.Mov", date];
    
    if (part > 0) {
        
        filename = [NSString stringWithFormat:@"iSting_%@ Part-%ld.Mov", [dateform1 stringFromDate:[NSDate date]],(long)part];
        
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   data, @"video.mov",
                                   @"video/quicktime", @"contentType",
                                   @"iSting", @"title",
                                   filename, @"description",
                                   nil];
    //
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"dd_MMMM_YYYY"];
    
    
    if ([FBSDKAccessToken currentAccessToken]) {
        
        NSLog(@"starting connection");
        FBSDKGraphRequest *connection = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/videos" parameters:params HTTPMethod:@"POST"];
        
       
        if ([[UIDevice currentDevice] isMultitaskingSupported]){
            
            _backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                NSLog(@"Expiration handler called %f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
                _backgroundTaskID = 0;
                [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                
            }];}
        
        [connection startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
            
            if (!error) {
              
                UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                
                if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
                    _backgroundTaskID = 0;
                    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                    _backgroundTaskID = UIBackgroundTaskInvalid;
                    [self presentNotification:@"Facebook VideoUpload Sucess"];
                }
                UIAlertView *alert;
                alert = [[UIAlertView alloc] initWithTitle: @"Success"
                                                   message: @"Video Uploaded Successfully!"
                                                  delegate: nil
                                         cancelButtonTitle: @"OK"
                                         otherButtonTitles: nil];
                [alert show];
                
                NSLog(@"Video uploaded %@",result);
                
            } else {
              
                UIApplicationState state = [[UIApplication sharedApplication] applicationState];
                
                if ([[UIDevice currentDevice] isMultitaskingSupported] && state == UIApplicationStateBackground) {
                    _backgroundTaskID = 0;
                    [[UIApplication sharedApplication] endBackgroundTask:_backgroundTaskID];
                    _backgroundTaskID = UIBackgroundTaskInvalid;
                    [self presentNotification:@"Facebook VideoUpload Failed"];
                }
                NSLog(@"Video uploaded failed %@",error.userInfo);
                
            }
            
        }];
        
    }
}

-(void)presentNotification:(NSString *)alerbody{
    
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    
    localNotification.alertBody = alerbody;
    localNotification.alertAction = @"Background Transfer Download!";
    
    //On sound
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    //increase the badge number of application plus 1
    localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
}


@end
