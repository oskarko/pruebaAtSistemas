//
//  RSSNewsCustomCell.h
//  atSistemasLectorRSS
//
//  Created by Oscar Rodriguez Garrucho on 9/6/17.
//  Copyright © 2017 Oscar Rodriguez Garrucho. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RSSNewsCustomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblinfo;
@property (weak, nonatomic) IBOutlet UIImageView *imgView;

@end
