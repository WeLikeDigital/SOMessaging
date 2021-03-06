//
//  SOMessagingViewController.m
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

#import "SOMessagingViewController.h"
#import "NSString+Calculation.h"
#import "SOImageBrowserView.h"
#import <MediaPlayer/MediaPlayer.h>

#define kMessageMaxWidth 240.0f

static NSString *const kMessageDateBackgroundImageName = @"messagesDateBackground";
static NSString *const kReceiveBubbleImageName = @"received";
static NSString *const kSendingBubbleImageName = @"sending";
static NSString *const kNotSentBubbleImageName = @"not_sent";
static NSString *const kSentBubbleImageName = @"sent";
static NSString *const kDeliveredBubbleImageName = @"delivered";
static NSString *const kReadBubbleImageName = @"read";
static NSString *const kTypingBubbleImageName = @"typing";

@interface SOMessagingViewController () <UITableViewDelegate, UIGestureRecognizerDelegate>
{
    
}

@property (strong, nonatomic) UIImage *balloonSendImage;
@property (strong, nonatomic) UIImage *balloonReceiveImage;

@property (strong, nonatomic) UIView *tableViewHeaderView;

@property (strong, nonatomic) NSMutableArray *conversation;


@property (strong, nonatomic) SOImageBrowserView *imageBrowser;
@property (strong, nonatomic) MPMoviePlayerViewController *moviePlayerController;
@property (assign) BOOL insideBubble;

- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification;
- (void)didReceiveMenuWillHideNotification:(NSNotification *)notification;
-(void)longPress:(UILongPressGestureRecognizer *) gesture;
@end

@implementation SOMessagingViewController {
    dispatch_once_t onceToken;
}

@synthesize selectedIndexPathForMenu;

- (void)setup
{
    [self setupTableView];
    [self setupInputView];
}

-(void) setupTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor colorWithRed:232.0/255.0
                                                     green:236.0/255.0
                                                      blue:238.0/255.0
                                                     alpha:1.0];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.tableViewHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 10)];
    self.tableViewHeaderView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = self.tableViewHeaderView;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    [self.view addSubview:self.tableView];
}

-(void) setupInputView
{
    self.messageInputView = [[SOMessageInputView alloc] init];
    self.messageInputView.tintColor = [UIColor blueColor];
    self.messageInputView.delegate = self;
    self.messageInputView.tableView = self.tableView;
    [self.view addSubview:self.messageInputView];
    [self.messageInputView adjustPosition];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];
    [self addLongPressGesture];
    [self subscribeForMenuNotifications];
    [self setupBalloonsImages];
}

-(void) addLongPressGesture
{
    if ([self shouldShowMenuOnLongPress])
    {
        UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                                 action:@selector(longPress:)];
        longPressGestureRecognizer.minimumPressDuration = 0.1;
        [self.tableView addGestureRecognizer:longPressGestureRecognizer];
    }
}

-(void) setupBalloonsImages
{
    self.balloonSendImage = [self balloonImageForSent];
    self.balloonReceiveImage = [self balloonImageForReceived];
}

-(void)longPress:(UILongPressGestureRecognizer *) gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint point = [gesture locationInView:self.tableView];
        NSIndexPath *path = [self.tableView indexPathForRowAtPoint:point];
        SOMessageCell *cell = (SOMessageCell *)[self.tableView cellForRowAtIndexPath:path];
        point = [gesture locationInView:cell.containerView];
        self.insideBubble = CGRectContainsPoint(cell.balloonImageView.frame, point);
    }
}

-(void) subscribeForMenuNotifications
{
    if ([self shouldShowMenuOnLongPress]) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMenuWillShowNotification:)
                                                     name:UIMenuControllerWillShowMenuNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMenuWillHideNotification:)
                                                     name:UIMenuControllerWillHideMenuNotification
                                                   object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.conversation = [self grouppedMessages];
    [self.tableView reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    dispatch_once(&onceToken, ^{
        if ([self.conversation count]) {
            NSInteger section = self.conversation.count - 1;
            NSInteger row = [self.conversation[section] count] - 1;
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            if (indexPath.row !=-1) {
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
        }
    });
}

// This code will work only if this vc hasn't navigation controller
- (BOOL)shouldAutorotate
{
    return !self.messageInputView.viewIsDragging;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.conversation.count;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    if (section < 0) {
        return 0;
    }
    // Return the number of rows in the section.
//    NSLog(@"SECTION = %ld ROWS = %ld", (long)section, (long)[self.conversation[section] count]);
    return [self.conversation[section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height;
    
    id<SOMessage> message = self.conversation[indexPath.section][indexPath.row];
    int index = (int)[[self messages] indexOfObject:message];
    height = [self heightForMessageForIndex:index];
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self intervalForMessagesGrouping])
        return [self headerSectionHeight];
    
    return 0.01f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (![self intervalForMessagesGrouping])
        return nil;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, [self headerSectionHeight])];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    view.backgroundColor = [UIColor clearColor];
    
    id<SOMessage> firstMessageInGroup = [self.conversation[section] firstObject];
    NSDate *date = [firstMessageInGroup date];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = [self conversationFormattedDate:date];
    
    label.textColor = [self headerSectionFontColor];
    label.font = [self headerSectionFont];
    [label sizeToFit];
    
    label.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    label.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    UIImage *backgroundImage = [UIImage imageNamed:kMessageDateBackgroundImageName];
    if (backgroundImage) {
        label.textColor = [UIColor whiteColor];
        UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(10, 20, 10, 20)]];
        CGFloat width = label.frame.size.width + 20;
        
        backgroundView.frame = CGRectMake(0, 0, width, 20);
        backgroundView.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
        [view addSubview:backgroundView];
    }
    
    [view addSubview:label];
    
    return view;
}

- (NSString *) conversationFormattedDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd MMM, eee, HH:mm"];
    return [formatter stringFromDate:date];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"sendCell";
    
    SOMessageCell *cell;
    
    id<SOMessage> message = self.conversation[indexPath.section][indexPath.row];
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[SOMessageCell alloc] initWithStyle:UITableViewCellStyleDefault
                                    reuseIdentifier:cellIdentifier
                                    messageMaxWidth:[self messageMaxWidth]];
    }
    [cell setMediaImageViewSize:[self mediaThumbnailSize]];
    [cell setUserImageViewSize:[self userImageSize]];
    cell.tableView = self.tableView;
    cell.balloonMinHeight = [self balloonMinHeight];
    cell.balloonMinWidth  = [self balloonMinWidth];
    cell.delegate = self;
    cell.messageFont = [self messageFont];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.balloonImage = message.fromMe ? self.balloonSendImage : self.balloonReceiveImage;
    cell.textView.textColor = message.fromMe ? [UIColor whiteColor] : [UIColor blackColor];
    cell.message = message;
    
    // For user customization
    int index = (int)[[self messages] indexOfObject:message];
    [self configureMessageCell:cell
             forMessageAtIndex:index];
    
    [cell adjustCell];
    
    cell.textView.selectable = YES;
    
    return cell;
}

#pragma mark - SOMessaging datasource
- (NSMutableArray *)messages
{
    return nil;
}

- (CGFloat)heightForMessageForIndex:(NSInteger)index
{
    CGFloat height;
    
    id<SOMessage> message = [self messages][index];
    
    if (message.type == SOMessageTypeText) {
        height = [self calculateHeightForMessage:message];
        
    } else {
        CGSize size = [self mediaThumbnailSize];
        if (size.height < [self userImageSize].height) {
            size.height = [self userImageSize].height;
        }
        height = size.height + kBubbleTopMargin + kBubbleBottomMargin;
    }
    return height;
}

-(CGFloat) calculateHeightForMessage:(id < SOMessage >) message
{
    CGSize size = [message.body usedSizeForMaxWidth:[self messageMaxWidth]
                                           withFont:[self messageFont]];
    if (message.attributes) {
        size = [message.body usedSizeForMaxWidth:[self messageMaxWidth]
                                  withAttributes:message.attributes];
    }
    
    if (self.balloonMinWidth) {
        CGFloat messageMinWidth = self.balloonMinWidth - [SOMessageCell messageLeftMargin] - [SOMessageCell messageRightMargin];
        messageMinWidth -= [message fromMe] ? 0 : 10;
        if (size.width <  messageMinWidth) {
            size.width = messageMinWidth;
            
            CGSize newSize = [message.body usedSizeForMaxWidth:messageMinWidth
                                                      withFont:[self messageFont]];
            if (message.attributes) {
                newSize = [message.body usedSizeForMaxWidth:messageMinWidth
                                             withAttributes:message.attributes];
            }
            
            size.height = newSize.height;
        }
    }
    
    CGFloat messageMinHeight = self.balloonMinHeight - ([SOMessageCell messageTopMargin] + [SOMessageCell messageBottomMargin]);
    if ([self balloonMinHeight] && size.height < messageMinHeight) {
        size.height = messageMinHeight;
    }
    
    size.height += [SOMessageCell messageTopMargin] + [SOMessageCell messageBottomMargin];
    
    if (!CGSizeEqualToSize([self userImageSize], CGSizeZero)) {
        if (size.height < [self userImageSize].height) {
            size.height = [self userImageSize].height;
        }
    }
    
    return size.height + kBubbleTopMargin + kBubbleBottomMargin;
}

- (NSTimeInterval)intervalForMessagesGrouping
{
    return 0;
}

- (UIImage *)balloonImageForReceived
{
    UIImage *bubble = [UIImage imageNamed:kReceiveBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(17, 27, 21, 17)];
}

- (UIImage *)balloonImageForError
{
    UIImage *bubble = [UIImage imageNamed:kNotSentBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(23, 21, 16, 27)];
}

- (UIImage *)balloonImageForSent
{
    UIImage *bubble = [UIImage imageNamed:kSentBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(18, 18, 18, 18)];
}

- (UIImage *)balloonImageForSending
{
    UIImage *bubble = [UIImage imageNamed:kSendingBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(23, 21, 16, 27)];
}

- (UIImage *)balloonImageForDelivered
{
    UIImage *bubble = [UIImage imageNamed:kDeliveredBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(23, 21, 16, 35)];
}

- (UIImage *)balloonImageForRead
{
    UIImage *bubble = [UIImage imageNamed:kReadBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(23, 21, 16, 35)];
}

- (UIImage *)balloonImageForTyping
{
    UIImage *bubble = [UIImage imageNamed:kTypingBubbleImageName];
    return [bubble resizableImageWithCapInsets:UIEdgeInsetsMake(17, 27, 21, 17)];
}

- (void)configureMessageCell:(SOMessageCell *)cell forMessageAtIndex:(NSInteger)index
{
}

- (CGFloat)messageMaxWidth
{
    return kMessageMaxWidth;
}

- (CGFloat)balloonMinHeight
{
    return 0;
}

- (CGFloat)balloonMinWidth
{
    return 0;
}

- (UIFont *)messageFont
{
    return [UIFont fontWithName:@"AvenirNextCyr-Light" size:14];
}

- (CGSize)mediaThumbnailSize
{
    CGFloat size = [UIScreen mainScreen].bounds.size.width/2;
    return CGSizeMake(size, size-12);
}

- (CGSize)userImageSize
{
    return CGSizeMake(0, 0);
}

-(UIFont *)headerSectionFont
{
    return [UIFont fontWithName:@"AvenirNextCyr-Light" size:11];
}

-(UIColor *)headerSectionFontColor
{
    return [UIColor grayColor];
}

-(CGFloat)headerSectionHeight
{
    return 40;
}

#pragma mark - Public methods
- (void)sendMessage:(id<SOMessage>) message
{
    message.fromMe = YES;
    NSMutableArray *messages = [self messages];
    [messages addObject:message];
    
    [self refreshMessagesAndScroll:YES];
}

- (void)receiveMessage:(id<SOMessage>) message
{
    message.fromMe = NO;
    
    NSMutableArray *messages = [self messages];
    [messages addObject:message];
    
    [self refreshMessagesAndScroll:YES];
}

-(void) refreshForMessage:(id<SOMessage>) message
                andScroll:(BOOL)needScroll
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self == %@", message];
    NSInteger foundRow = NSNotFound;
    NSInteger foundSection = NSNotFound;
    
    for (NSInteger index = 0; index < self.conversation.count; index++) {
        id<SOMessage> foundMessage = [[self.conversation[index] filteredArrayUsingPredicate:predicate] firstObject];
        if (foundMessage) {
            foundRow = [self.conversation[index] indexOfObject:foundMessage];
            foundSection = index;
            break;
        }
    }
    
    NSIndexPath *indexPath = nil;
    
    if ((foundSection != NSNotFound) && (foundRow != NSNotFound)) {
        indexPath = [NSIndexPath indexPathForRow:foundRow
                                       inSection:foundSection];
        
//        NSLog(@"RELOAD OLD ROW = %ld", (long)foundRow);
        [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
    else {
        self.conversation = [self grouppedMessages];
        
        NSInteger section = ([self numberOfSectionsInTableView:self.tableView] - 1) ? : 0;
        NSInteger row     = [self tableView:self.tableView
                      numberOfRowsInSection:section] - 1;
        
        indexPath = [NSIndexPath indexPathForRow:row
                                       inSection:section];
        
        
        
        //        NSLog(@"INSERT NEW ROW = %ld", (long)row);
        if (row == [self.conversation[section] count]-1) {
            @try {
                [self.tableView insertRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationBottom];
            }
            @catch (NSException *exception) {
                [self.tableView reloadData];
            }
        }
    }
    
    if (needScroll) {
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionBottom
                                      animated:YES];
    }
}

- (void)refreshMessagesAndScroll:(BOOL)needScroll;
{
    self.conversation = [self grouppedMessages];
    
    [self.tableView reloadData];
    
    self.tableView.tableFooterView = nil;
    
    if (needScroll) {
        NSInteger section = [self numberOfSectionsInTableView:self.tableView] - 1;
        NSInteger row     = [self tableView:self.tableView numberOfRowsInSection:section] - 1;
        
        if (row >= 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row
                                                        inSection:section];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionBottom
                                          animated:YES];
        }
    }
}

-(void)refreshUploadingStatus
{
    NSMutableArray* mediaUploadingCellsIndexPaths = [@[] mutableCopy];
    
    for (id<SOMessage> message in self.messages) {
        if (message.isUploading) {
            NSIndexPath *indexPath = [self indexPathForMessage:message];
            if (indexPath) {
                [mediaUploadingCellsIndexPaths addObject:indexPath];
            }
        }
    }
    
    [self.tableView reloadRowsAtIndexPaths:mediaUploadingCellsIndexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
}

-(NSIndexPath *)indexPathForMessage:(id<SOMessage>)message
{
    for (NSInteger section=0; section<self.conversation.count; section++) {
        NSArray *conversation = self.conversation[section];
        NSUInteger row = [conversation indexOfObject:message];
        if (row != NSNotFound) {
            return [NSIndexPath indexPathForRow:row
                                      inSection:section];
        }
    }
    return nil;
}

#pragma mark - Private methods
- (NSMutableArray *)grouppedMessages
{
    NSMutableArray *conversation = [NSMutableArray new];
    
    if (![self intervalForMessagesGrouping]) {
        if ([self messages]) {
            [conversation addObject:[self messages]];
        }
    }
    else {
        NSInteger groupIndex = 0;
        NSMutableArray *allMessages = [self messages];
        
        for (NSInteger i = 0; i < allMessages.count; i++) {
            if (i == 0) {
                NSMutableArray *firstGroup = [NSMutableArray new];
                [firstGroup addObject:allMessages[i]];
                [conversation addObject:firstGroup];
            }
            else {
                id<SOMessage> prevMessage    = allMessages[i-1];
                id<SOMessage> currentMessage = allMessages[i];
                
                NSDate *prevMessageDate    = prevMessage.date;
                NSDate *currentMessageDate = currentMessage.date;
                
                NSTimeInterval interval = [currentMessageDate timeIntervalSinceDate:prevMessageDate];
                if (interval < [self intervalForMessagesGrouping]) {
                    NSMutableArray *group = conversation[groupIndex];
                    [group addObject:currentMessage];
                    
                } else {
                    NSMutableArray *newGroup = [NSMutableArray new];
                    [newGroup addObject:currentMessage];
                    [conversation addObject:newGroup];
                    groupIndex++;
                }
            }
        }
    }
    
    return conversation;
}

#pragma mark - SOMessaging delegate
- (void)messageCell:(SOMessageCell *)cell
        didTapMedia:(NSData *)media
{
    [self didSelectMedia:media
           inMessageCell:cell];
}

- (void)didSelectMedia:(NSData *)media
         inMessageCell:(SOMessageCell *)cell
{
    if (cell.message.type == SOMessageTypePhoto) {
        self.imageBrowser = [[SOImageBrowserView alloc] init];
        
        self.imageBrowser.image = [UIImage imageWithData:cell.message.media];
        
        self.imageBrowser.startFrame = [cell convertRect:cell.containerView.frame toView:self.view];
        
        [self.imageBrowser show];
    } else if (cell.message.type == SOMessageTypeVideo) {
        
        NSString *appFile = [NSTemporaryDirectory() stringByAppendingPathComponent:@"video.mp4"];
        [cell.message.media writeToFile:appFile atomically:YES];
        
        
        self.moviePlayerController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:appFile]];
        [self.moviePlayerController.moviePlayer prepareToPlay];
        [self.moviePlayerController.moviePlayer setShouldAutoplay:YES];
        
        [self presentViewController:self.moviePlayerController animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
        }];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}

-(void)messageInputViewDidChange:(SOMessageInputView *)inputView
{
    
}

-(void) didTapMessageCell:(SOMessageCell *) cell
{
    if (!self.selectedIndexPathForMenu) {
        if (cell.message.type != SOMessageTypeText) {
            [self didSelectMedia:cell.message.media
                   inMessageCell:cell];
        }
    }
}

-(BOOL)tableView:(UITableView *)tableView
shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL result = [self shouldShowMenuOnLongPress] && self.insideBubble;
    if (result) {
        self.selectedIndexPathForMenu = indexPath;
        SOMessageCell *cell = (SOMessageCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.textView.selectable = NO;
    }
    return result;
}

-(BOOL) shouldShowMenuOnLongPress
{
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView
canPerformAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
      withSender:(id)sender
{
    return ![self shouldShowMenuOnLongPress];
}

-(void)tableView:(UITableView *)tableView
   performAction:(SEL)action
forRowAtIndexPath:(NSIndexPath *)indexPath
      withSender:(id)sender
{
    
}

#pragma mark - Notifications
- (void)didReceiveMenuWillShowNotification:(NSNotification *)notification
{
    if (self.selectedIndexPathForMenu) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIMenuControllerWillShowMenuNotification
                                                      object:nil];
        
        UIMenuController *menu = [notification object];
        UIMenuItem *sendItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Send", @"")
                                                          action:@selector(send:)];
        UIMenuItem *deleteItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Delete", @"")
                                                            action:@selector(deleteMessage:)];
        [menu setMenuItems:@[sendItem, deleteItem]];
        [menu setMenuVisible:NO
                    animated:NO];
        
        SOMessageCell *cell = (SOMessageCell *)[self.tableView cellForRowAtIndexPath:self.selectedIndexPathForMenu];
        
        CGRect selectedCellMessageBubbleFrame = [cell convertRect:cell.balloonImageView.frame
                                                           toView:self.view];
        
        if (cell.message.fromMe) {
            selectedCellMessageBubbleFrame.origin.x += [UIScreen mainScreen].bounds.size.width - selectedCellMessageBubbleFrame.size.width;
        }
        
        [menu setTargetRect:CGRectMake(selectedCellMessageBubbleFrame.origin.x, selectedCellMessageBubbleFrame.origin.y, 50, 50)//selectedCellMessageBubbleFrame
                     inView:self.view];
        
        [menu setMenuVisible:YES
                    animated:YES];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMenuWillShowNotification:)
                                                     name:UIMenuControllerWillShowMenuNotification
                                                   object:nil];
    }
}

-(void)didReceiveMenuWillHideNotification:(NSNotification *)notification
{
    if (self.selectedIndexPathForMenu) {
        SOMessageCell *cell = (SOMessageCell *)[self.tableView cellForRowAtIndexPath:self.selectedIndexPathForMenu];
        self.selectedIndexPathForMenu = nil;
        cell.textView.selectable = YES;
    }
}

#pragma mark - Helper methods
- (UIImage *)tintImage:(UIImage *)image withColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGContextClipToMask(context, rect, image.CGImage);
    //    [color setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillShowMenuNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillShowMenuNotification
                                                  object:nil];
}

@end
