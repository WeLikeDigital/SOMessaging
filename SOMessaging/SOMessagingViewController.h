//
//  SOMessagingViewController.h
//  SOMessaging
//
// Created by : arturdev
// Copyright (c) 2014 SocialObjects Software. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE

#import <UIKit/UIKit.h>
#import "SOMessageType.h"
#import "SOMessagingDataSource.h"
#import "SOMessagingDelegate.h"
#import "SOMessageInputView.h"
#import "SOMessage.h"
#import "SOMessageCell.h"

@protocol LongPressOnCell <NSObject>

-(BOOL) shouldShowMenuOnLongPress;

@end

@interface SOMessagingViewController : UIViewController <SOMessagingDataSource, SOMessagingDelegate, UITableViewDataSource, LongPressOnCell, SOMessageCellDelegate>

#pragma mark - Properties
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) SOMessageInputView *inputView;

#pragma mark - Methods
/**
 * Add new balloon to tableView in right side
 */
- (void)sendMessage:(id<SOMessage>)message;

/**
 * Add new balloon to tableView in left side
 */
- (void)receiveMessage:(id<SOMessage>)message;

/**
 * Reloading datasource
 */
 -(void) refreshMessagesAndScroll:(BOOL)needScroll;
 
-(void) refreshForMessage:(id<SOMessage>) message
                andScroll:(BOOL)needScroll;

/**
 * Reloading only uploading media cells
 */
-(void)refreshUploadingStatus;

@end
