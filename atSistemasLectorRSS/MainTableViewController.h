//
//  MainTableViewController.h
//  atSistemasLectorRSS
//
//  Created by Oscar Rodriguez Garrucho on 9/6/17.
//  Copyright © 2017 Oscar Rodriguez Garrucho. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainTableViewController : UITableViewController <NSXMLParserDelegate>

@property (nonatomic,strong) NSMutableArray *rssNews;

@property (nonatomic, strong) NSMutableDictionary *dictData;
@property (nonatomic,strong) NSMutableArray *marrXMLData;
@property (nonatomic,strong) NSMutableString *mstrXMLString;
@property (nonatomic,strong) NSMutableDictionary *mdictXMLPart;

@end
