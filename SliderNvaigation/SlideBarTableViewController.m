//
//  SlideBarTableViewController.m
//  SliderNvaigation
//
//  Created by Fluxtech_MacMini1 on 3/8/16.
//  Copyright © 2016 Fluxtech_MacMini1. All rights reserved.
//

#import "SlideBarTableViewController.h"
#import "SWRevealViewController.h"

@interface SlideBarTableViewController ()<DBRestClientDelegate>{
    
    NSArray *menuItems;
    NSMutableArray *SocialMediaArray,*iconArray;
    BOOL ODClientAuth;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) DBRestClient *restClient;

@end

@implementation SlideBarTableViewController

- (void)viewDidLoad {
   
    [super viewDidLoad];
    
    menuItems = @[@"title", @"news", @"comments", @"map", @"calendar", @"wishlist", @"bookmark", @"tag"];
    ODClientAuth = NO;
    self.service = [[GTLServiceDrive alloc] init];
    self.service.authorizer = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                    clientID:kClientID
                                                                                clientSecret:kClientSecret];
    if (!SocialMediaArray) {
        
        SocialMediaArray = [[NSMutableArray alloc]initWithObjects:@"OneDrive",@"GoogleDrive",@"DropBox",@"Facebook", nil];
    }
    
    if (!iconArray) {
        
        iconArray = [[NSMutableArray alloc]initWithObjects:@"OneDrive",@"GoogleDrive",@"DropBox",@"Facebook", nil];
    }
    
#pragma OneDrive Setup
    
    if (!self.client){
        self.client = [ODClient loadCurrentClient];
    }
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    
    if (ODClientAuth) {
        [SVProgressHUD showWithStatus:@"Login Please Wait ..." maskType:SVProgressHUDMaskTypeNone];
        ODClientAuth = NO;
    }
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma TableView Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [SocialMediaArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    SettingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        
        cell = [[SettingTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    [cell.switchOutlet setOn:NO animated:NO];
    
    if (indexPath.row == 0) {
        
        if (!self.client){
            self.client = [ODClient loadCurrentClient];
        }
        if (self.client){
            
            [cell.switchOutlet setOn:YES animated:NO];
        }
        
    } else if (indexPath.row == 1) {
        
        if (self.service.authorizer.canAuthorize) {
            
            [cell.switchOutlet setOn:YES animated:NO];
        }
        
    }
    
    else if (indexPath.row == 2) {
        
        if ([[DBSession sharedSession] isLinked]) {
            
            [cell.switchOutlet setOn:YES animated:NO];
            
        }
        
    }
    else  if (indexPath.row == 3) {
        
        
        if ([FBSDKAccessToken currentAccessToken]){
            
            [cell.switchOutlet setOn:YES animated:NO];
            
        }
    }
    
    
    [cell.name setText:[SocialMediaArray objectAtIndex:indexPath.row]];
    [cell.iconImage setImage:[UIImage imageNamed:[iconArray objectAtIndex:indexPath.row]]];
    cell.switchOutlet.tag = indexPath.row;
    [cell.switchOutlet addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    
    return cell;
    
}

- (void) switchChanged:(UISwitch *)sender {
    
#pragma SignOut From other SocialMedia..
    if ([FBSDKAccessToken currentAccessToken]) {
        
        [FBSDKAccessToken setCurrentAccessToken:nil];
        NSLog(@"Token String : %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
        NSLog(@"Fb Logout SuccessFully");
        
        
    }
    if ([[DBSession sharedSession] isLinked]) {
        
        [[DBSession sharedSession] unlinkAll];
        NSLog(@"DropBox Logout Success");
        
    }
    if (self.service.authorizer.canAuthorize) {
        
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        NSLog(@"GoogleDrive Logout Success");
    }
    
    if (self.client) {
        
        [self.client signOutWithCompletion:^(NSError *error){
            
            if (!error) {
                
                NSLog(@"OneDrive Logout Success");
                
            }else NSLog(@"Error While SignOut : %@",error);
        }];
    }
    
    UISwitch* switchControl = sender;
    NSLog(@"TAG VAlue =%ld",(long)sender.tag);
    
    if (sender.tag == 0) {
        
        if ([sender isOn]) {
            
            for (int i = 0; i<[SocialMediaArray count]; i++) {
                
                NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                SettingTableViewCell * cell = [self.tableView cellForRowAtIndexPath:ip];
                
                if (i != sender.tag) {
                    
                    [cell.switchOutlet setOn:NO animated:YES];
                    
                }
                
            }
            
#pragma Login With OneDrive
            
            [ODClient authenticatedClientWithCompletion:^(ODClient *client, NSError *error){
                
                if (!error){
                    
                    [SVProgressHUD dismiss];
                    self.client = client;
                    [switchControl setOn:YES animated:YES];
                  //  [_delegetClient Client:self.client];
                    
                }
                
                else{
                    
                    NSLog(@"OneDrive SigIn Error : %@",error);
                    [switchControl setOn:NO animated:YES];
                    
                }
            }];
            
            ODClientAuth = YES;
            
        }
        
        else if (![sender isOn]){
            
            [self.client signOutWithCompletion:^(NSError *error){
                
                if (!error) {
                    
                    [SVProgressHUD dismiss];
                    [switchControl setOn:NO animated:YES];
                    
                }else{
                    
                    NSLog(@"error : %@",error);
                    
                }
                
            }];
            
            [SVProgressHUD showWithStatus:@"Logout From OneDrive please wait..." maskType:SVProgressHUDMaskTypeNone];
        }
        
        
    } else if (sender.tag == 1){
        
        if ([sender isOn]) {
            
            for (int i = 0; i<[SocialMediaArray count]; i++) {
                
                NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                SettingTableViewCell * cell = [self.tableView cellForRowAtIndexPath:ip];
                
                if (i != sender.tag) {
                    
                    [cell.switchOutlet setOn:NO animated:YES];
                    
                }
                
            }
            
#pragma Login With Google Drive.....
            
            if (!self.service.authorizer.canAuthorize) {
                
                [self presentViewController:[self createAuthController] animated:YES completion:nil];
                [switchControl setOn:YES animated:YES];
                
            }else if (self.service.authorizer.canAuthorize){
                
                [switchControl setOn:YES animated:YES];
                
            }
            
        }else if (![sender isOn]){
            
            [switchControl setOn:NO animated:YES];
            
            [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
            
        }
        
    }
    
    else if (sender.tag == 2){
        
        if ([sender isOn]) {
            
            for (int i = 0; i<[SocialMediaArray count]; i++) {
                
                NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                SettingTableViewCell * cell = [self.tableView cellForRowAtIndexPath:ip];
                
                if (i != sender.tag) {
                    
                    [cell.switchOutlet setOn:NO animated:YES];
                    
                }
                
            }
            
#pragma Login With DropBox
            
            self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
            self.restClient.delegate = self;
            
            if (![[DBSession sharedSession] isLinked]) {
                
                [[DBSession sharedSession] linkFromController:self];
                
            }
            
            [switchControl setOn:YES animated:YES];
            
        }else if (![sender isOn]){
            
            [[DBSession sharedSession] unlinkAll];
            [switchControl setOn:NO animated:YES];
            
        }
        
    }    else if (sender.tag == 3){
        
        FBSDKLoginManager *loginManager = [[FBSDKLoginManager alloc] init];
        
        if ([sender isOn]) {
            
            for (int i = 0; i<[SocialMediaArray count]; i++) {
                
                NSIndexPath *ip = [NSIndexPath indexPathForRow:i inSection:0];
                SettingTableViewCell * cell = [self.tableView cellForRowAtIndexPath:ip];
                
                if (i != sender.tag) {
                    
                    [cell.switchOutlet setOn:NO animated:YES];
                    
                }
                
            }
            
#pragma Login With Facebook
            
            [loginManager logInWithPublishPermissions:@[@"publish_actions"] handler:^(FBSDKLoginManagerLoginResult *result, NSError *error){
                
                if ([FBSDKAccessToken currentAccessToken]) {
                    
                    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                                  initWithGraphPath:@"me"
                                                  parameters:@{@"fields": @"id,name,email"}
                                                  HTTPMethod:@"GET"];
                    
                    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                                          id result,
                                                          NSError *error) {
                        
                        if (!error) {
                            
                            [switchControl setOn:YES animated:YES];
                            NSLog(@"Current Access Token : %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
                            NSLog(@"result : %@",result);
                            
                        }
                    }];
                    
                }
                
                
            }];
            
        }else if (![sender isOn]){
            
            [FBSDKAccessToken setCurrentAccessToken:nil];
            NSLog(@"Token String : %@",[[FBSDKAccessToken currentAccessToken] tokenString]);
            [loginManager logOut];
            [switchControl setOn:NO animated:YES];
        }
    }
    
    
}


#pragma GoogleDrive Login Authorization

- (GTMOAuth2ViewControllerTouch *)createAuthController {
    
    GTMOAuth2ViewControllerTouch *authController;
    authController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeDriveFile
                                                                clientID:kClientID
                                                            clientSecret:kClientSecret
                                                        keychainItemName:kKeychainItemName
                                                                delegate:self
                                                        finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    return authController;
    
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    
    if (error != nil) {
        
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
        
    }
    else {
        
        self.service.authorizer = authResult;
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }
}


- (void)displayResultWithTicket:(GTLServiceTicket *)ticket
             finishedWithObject:(GTLDriveFileList *)response
                          error:(NSError *)error {
}


- (void)showAlert:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert;
    alert = [[UIAlertView alloc] initWithTitle: title
                                       message: message
                                      delegate: nil
                             cancelButtonTitle: @"OK"
                             otherButtonTitles: nil];
    [alert show];
}
- (void)showErrorAlert:(NSError*)error
{
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"There was an Error!"
                                                                        message:[NSString stringWithFormat:@"%@", error]
                                                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
    [errorAlert addAction:ok];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:errorAlert animated:YES completion:nil];
    });
    
}


- (IBAction)hiddenRecording:(id)sender {
    
    if (self.hiddenRecording.selected) {
        [self.hiddenRecording setSelected:NO];
    }else if (!self.hiddenRecording.selected){
        UIAlertController * view =   [UIAlertController
                                      alertControllerWithTitle:@"Instruction"
                                      message:@"Recording screen will be hide and double tap anywere on screen to start recording and Single tap anywere on screen to stop recording."
                                      preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self.hiddenRecording setSelected:YES];
                                 [DELEGATE setHideScreen:YES];
                                 NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                 [defaults setBool:YES forKey:@"hideScreen"];
                                 [defaults synchronize];
                             }];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"cancel"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [self.hiddenRecording setSelected:NO];
                                     [DELEGATE setHideScreen:NO];
                                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                     [defaults setBool:NO forKey:@"hideScreen"];
                                     [defaults synchronize];
                                 }];
        [view addAction:ok];
        [view addAction:cancel];
        [self presentViewController:view animated:YES completion:nil];
        
    }
}
- (IBAction)applaunchRecording:(id)sender {
    
    if (self.applauncgRecording.selected) {
        [self.applauncgRecording setSelected:NO];
    }else if (!self.applauncgRecording.selected){
        UIAlertController * view =   [UIAlertController
                                      alertControllerWithTitle:@"Instruction"
                                      message:@"Recording automatically start when application launch."
                                      preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [self.applauncgRecording setSelected:YES];
                                 [DELEGATE setRecordingOnLaunch:YES];
                             }];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"cancel"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     [self.applauncgRecording setSelected:NO];
                                     [DELEGATE setRecordingOnLaunch:NO];
                                 }];
        [view addAction:ok];
        [view addAction:cancel];
        [self presentViewController:view animated:YES completion:nil];
    }}





@end
