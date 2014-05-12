//
//  SOMessagingViewController.h
//  SOSimpleChatDemo
//
//  Created by Artur Mkrtchyan on 4/23/14.
//  Copyright (c) 2014 SocialOjbects Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOMessageType.h"
#import "SOMessagingDataSource.h"
#import "SOMessagingDelegate.h"
#import "SOMessageInputView.h"
#import "SOMessage.h"
#import "SOMessageCell.h"


@interface SOMessagingViewController : UIViewController <SOMessagingDataSource, SOMessagingDelegate, UITableViewDataSource>

#pragma mark - Properties
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) SOMessageInputView *inputView;

#pragma mark - Methods
/**
 * Add new balloon to tableView in right side
 */
- (void)sendMessage:(SOMessage *)message;

/**
 * Add new balloon to tableView in left side
 */
- (void)receiveMessage:(SOMessage *)message;

/**
 * Reloading datasource
 */
- (void)refreshMessages;

@end