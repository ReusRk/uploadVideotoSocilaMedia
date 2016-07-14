//
//  SettingTableViewCell.h
//  JVFloatingDrawer
//
//  Created by Fluxtech_MacMini1 on 5/27/16.
//  Copyright © 2016 JVillella. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UISwitch *switchOutlet;

@end
