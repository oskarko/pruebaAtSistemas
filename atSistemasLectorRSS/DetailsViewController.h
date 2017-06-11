//
//  DetailsViewController.h
//  atSistemasLectorRSS
//
//  Created by Oscar Rodriguez Garrucho on 9/6/17.
//  Copyright © 2017 Oscar Rodriguez Garrucho. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailsViewController : UIViewController <NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTexView;
@property (nonatomic, strong) NSURLSession *session;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *safariButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *syncSpinner;

@property (nonatomic) int newsIdentifier;
@end
