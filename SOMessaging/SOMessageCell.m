//
//  SOMessageCell.m
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

#import "SOMessageCell.h"
#import "NSString+Calculation.h"
#import "DAProgressOverlayView.h"
#import "UIImageView+WebCache.h"

static const CGFloat kUserImageViewLeftMargin = 3;

@interface SOMessageCell() < UIGestureRecognizerDelegate>
{
    BOOL isHorizontalPan;
}
@property (nonatomic) CGSize mediaImageViewSize;
@property (nonatomic) CGSize userImageViewSize;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation SOMessageCell

static CGFloat messageTopMargin;
static CGFloat messageBottomMargin;
static CGFloat messageLeftMargin;
static CGFloat messageRightMargin;

static CGFloat maxContentOffsetX;
static CGFloat contentOffsetX;

static CGFloat userImageSideMargin;

static CGFloat bubbleRightMargin;
static CGFloat bubbleLeftMargin;

static CGFloat initialTimeLabelPosX;
static BOOL cellIsDragging;


-(BOOL)canPerformAction:(SEL)action
             withSender:(id)sender
{
    return [self isErrorMessageFor:action] || [self isDeleteMessageFor:action] || (action == @selector(copy:));
}

-(BOOL)isErrorMessageFor:(SEL)action
{
    return (action == @selector(send:) || action == @selector(deleteMessage:)) && self.message.status < 0;
}
                                                                         
-(BOOL)isDeleteMessageFor:(SEL)action
{
    return action == @selector(deleteMessage:) && self.message.fromMe && self.message.status > 0;
}

-(void)send:(id) sender
{
    [self.delegate didTapSendOnMessageCell:self];
}

-(void)deleteMessage:(id)sender
{
    [self.delegate didTapDeleteOnMessageCell:self];
}

-(void)copy:(id)sender
{
    [self.delegate didTapCopyOnMessageCell:self];
}

+ (void)load
{
    [self setDefaultConfigs];
}

+ (void)setDefaultConfigs
{
    messageTopMargin = 9;
    messageBottomMargin = 9;
    messageLeftMargin = 15;
    messageRightMargin = 25;
    
    userImageSideMargin = kUserImageViewLeftMargin;
    bubbleLeftMargin = kBubbleLeftMargin;
    bubbleRightMargin = kBubbleRightMargin;
    
    contentOffsetX = 0;
    maxContentOffsetX = 50;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier messageMaxWidth:(CGFloat)messageMaxWidth
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.messageMaxWidth = messageMaxWidth;
        self.backgroundColor = [UIColor clearColor];
        [self addPanGesture];
        [self setInitialSizes];
        [self setupOrientationNotification];
    }
    
    return self;
}

-(void) handleTap:(UITapGestureRecognizer *) tapGestureRecognizer
{
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.delegate didTapMessageCell:self];
    }
}

-(void) addPanGesture
{
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(handlePan:)];
    self.panGesture.delegate = self;
    [self addGestureRecognizer:self.panGesture];
}

- (void)setInitialSizes
{
    if (self.containerView) {
        [self.containerView removeFromSuperview];
    }
    if (self.timeLabel) {
        [self.timeLabel removeFromSuperview];
    }
    
    self.userImageView = [[UIImageView alloc] init];
    self.userImageView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.messageMaxWidth, 0)];

    self.timeLabel = [[UILabel alloc] init];

    self.mediaImageView = [[UIImageView alloc] init];

    self.mediaOverlayView = [[UIView alloc] init];

    self.balloonImageView = [[UIImageView alloc] init];
    self.balloonImageView.userInteractionEnabled = YES;
    
    if (!CGSizeEqualToSize(self.userImageViewSize, CGSizeZero)) {
        CGRect frame = self.userImageView.frame;
        frame.size = self.userImageViewSize;
        self.userImageView.frame = frame;
    }
    
    self.userImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.userImageView.clipsToBounds = YES;
    self.userImageView.backgroundColor = [UIColor clearColor];
    self.userImageView.layer.cornerRadius = 5;
    
    if (!CGSizeEqualToSize(self.mediaImageViewSize, CGSizeZero)) {
        CGRect frame = self.mediaImageView.frame;
        frame.size = self.mediaImageViewSize;
        self.mediaImageView.frame = frame;
    }
    
    self.mediaImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.mediaImageView.clipsToBounds = YES;
    self.mediaImageView.backgroundColor = [UIColor clearColor];
    self.mediaImageView.userInteractionEnabled = YES;
    
    self.mediaOverlayView.backgroundColor = [UIColor clearColor];
    [self.mediaImageView addSubview:self.mediaOverlayView];
    
    self.textView.textColor = [UIColor whiteColor];
    self.textView.backgroundColor = [UIColor clearColor];
    [self.textView setTextContainerInset:UIEdgeInsetsZero];
    self.textView.textContainer.lineFragmentPadding = 0;
    
    [self hideSubViews];
    
    self.containerView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [self.contentView addSubview:self.containerView];
    
    [self.containerView addSubview:self.balloonImageView];
    [self.containerView addSubview:self.textView];
    [self.containerView addSubview:self.mediaImageView];
    [self.containerView addSubview:self.userImageView];

    [self addTapGesture];

    self.contentView.clipsToBounds = NO;
    self.clipsToBounds = NO;
    
    self.timeLabel.font = [UIFont fontWithName:@"AvenirNextCyr-Light" size:11];
    self.timeLabel.textColor = [UIColor grayColor];
    self.timeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    
    UIImage *backgroundImage = [UIImage imageNamed:@"messagesDateBackground"];
    if (backgroundImage) {
        self.timeLabel.textColor = [UIColor whiteColor];
        if (self.backgroundImageView) {
            [self.backgroundImageView removeFromSuperview];
        }
        self.backgroundImageView = [[UIImageView alloc] initWithImage:[backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20)]];
        self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.contentView addSubview:self.backgroundImageView];
    }
    
    [self.contentView addSubview:self.timeLabel];
}

- (void)hideSubViews
{
    self.userImageView.hidden = YES;
    self.textView.hidden = YES;
    self.mediaImageView.hidden = YES;
}

-(void)addTapGesture
{
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handleTap:)];
    self.tapGestureRecognizer.delegate = self;
    [self.containerView addGestureRecognizer:self.tapGestureRecognizer];
}

-(void) setupOrientationNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleOrientationWillChandeNote:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification
                                               object:nil];
}

- (void)setMediaImageViewSize:(CGSize)size
{
    _mediaImageViewSize = size;
    CGRect frame = self.mediaImageView.frame;
    frame.size = size;
    self.mediaImageView.frame = frame;
}

- (void)setUserImageViewSize:(CGSize)size
{
    _userImageViewSize = size;
    CGRect frame = self.userImageView.frame;
    frame.size = size;
    self.userImageView.frame = frame;
}

- (void)setUserImage:(UIImage *)userImage
{
    _userImage = userImage;
    if (!userImage) {
        self.userImageViewSize = CGSizeZero;
    }
    [self adjustCell];
}

#pragma mark -
- (void)setMessage:(id<SOMessage>)message
{
    _message = message;
    
    [self setInitialSizes];
    //    [self adjustCell];
}

- (void)adjustCell
{
    [self hideSubViews];
    [self hideSubviewsViewsDependingOnMessageType];
    self.containerView.autoresizingMask = self.message.fromMe ? UIViewAutoresizingFlexibleLeftMargin : UIViewAutoresizingFlexibleRightMargin;
    initialTimeLabelPosX = self.timeLabel.frame.origin.x;
    /*
     --  Not implemented ---
     else if (self.message.type & (SOMessageTypePhoto | SOMessageTypeText)) {
     self.textView.hidden = NO;
     self.mediaImageView.hidden = NO;
     } else if (self.message.type & (SOMessageTypeVideo | SOMessageTypeText)) {
     self.textView.hidden = NO;
     self.mediaImageView.hidden = NO;
     }
     */
    
}

-(void) hideSubviewsViewsDependingOnMessageType
{
    if (self.message.type == SOMessageTypeText) {
        self.textView.hidden = NO;
        [self adjustForTextOnly];
    }
    else if (self.message.type == SOMessageTypePhoto) {
        self.mediaImageView.hidden = NO;
        [self adjustForPhotoOnly];
    }
    else if (self.message.type == SOMessageTypeVideo) {
        self.mediaImageView.hidden = NO;
        [self adjustForVideoOnly];
    }
    else if (self.message.type == SOMessageTypeOther) {
        if (!CGSizeEqualToSize(self.userImageViewSize, CGSizeZero) && self.userImage) {
            self.userImageView.hidden = NO;
        }
    }
}

- (void)adjustForTextOnly
{
    CGRect usedFrame = [self usedRectForWidth:self.messageMaxWidth];;
    if (self.balloonMinWidth) {
        CGFloat messageMinWidth = self.balloonMinWidth - messageLeftMargin - messageRightMargin;
        messageMinWidth -= [self.message fromMe] ? 0 : 10;
        if (usedFrame.size.width <  messageMinWidth) {
            usedFrame.size.width = messageMinWidth;
            
            usedFrame.size.height = [self usedRectForWidth:messageMinWidth].size.height;
        }
    }
    
    CGFloat messageMinHeight = self.balloonMinHeight - messageTopMargin - messageBottomMargin;
    
    if (self.balloonMinHeight && usedFrame.size.height < messageMinHeight) {
        usedFrame.size.height = messageMinHeight;
    }
    
    self.textView.font = self.messageFont;
    
    CGRect frame = self.textView.frame;
    frame.size.width  = usedFrame.size.width;
    frame.size.height = usedFrame.size.height;
    frame.origin.y = messageTopMargin;
    
    CGRect balloonFrame = self.balloonImageView.frame;
    balloonFrame.size.width = frame.size.width + messageLeftMargin + messageRightMargin;
    balloonFrame.size.height = frame.size.height + messageTopMargin + messageBottomMargin;
    balloonFrame.origin.y = 0;
    frame.origin.x = self.message.fromMe ? messageLeftMargin : (balloonFrame.size.width - frame.size.width);
    if (!self.message.fromMe && self.userImage) {
        frame.origin.x += userImageSideMargin + self.userImageViewSize.width;
        frame.origin.x -= self.message.fromMe ? 0 : messageRightMargin;
        balloonFrame.origin.x = userImageSideMargin + self.userImageViewSize.width;
    }
    
    frame.origin.x += self.contentInsets.left - self.contentInsets.right;
    
    self.textView.frame = frame;
    
    CGRect userRect = self.userImageView.frame;
    
    if (!CGSizeEqualToSize(userRect.size, CGSizeZero) && self.userImage) {
        if (balloonFrame.size.height < userRect.size.height) {
            balloonFrame.size.height = userRect.size.height;
        }
    }
    
    self.balloonImageView.frame = balloonFrame;
    self.balloonImageView.backgroundColor = [UIColor clearColor];
    self.balloonImageView.image = self.balloonImage;
    
    self.textView.editable = NO;
    self.textView.selectable = NO;
    self.textView.scrollEnabled = NO;
    self.textView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
    self.textView.tintColor = [UIColor blackColor];
    self.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : [UIColor blackColor],
                                          NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    if (self.userImageView.autoresizingMask & UIViewAutoresizingFlexibleTopMargin) {
        userRect.origin.y = balloonFrame.origin.y + balloonFrame.size.height - userRect.size.height;
    } else {
        userRect.origin.y = 0;
    }
    
    if (self.message.fromMe) {
        userRect.origin.x = balloonFrame.origin.x + userImageSideMargin + balloonFrame.size.width;
    } else {
        userRect.origin.x = balloonFrame.origin.x - userImageSideMargin - userRect.size.width;
    }
    self.userImageView.frame = userRect;
    self.userImageView.image = self.userImage;
    
    CGRect frm = self.containerView.frame;
    frm.origin.x = self.message.fromMe ? self.contentView.frame.size.width - balloonFrame.size.width - bubbleRightMargin : bubbleLeftMargin;
    frm.origin.y = kBubbleTopMargin;
    frm.size.height = balloonFrame.size.height;
    frm.size.width = balloonFrame.size.width;
    if (!CGSizeEqualToSize(userRect.size, CGSizeZero) && self.userImage) {
        self.userImageView.hidden = NO;
        frm.size.width += userImageSideMargin + userRect.size.width;
        if (self.message.fromMe) {
            frm.origin.x -= userImageSideMargin + userRect.size.width;
        }
    }
    
    
    if (frm.size.height < self.userImageViewSize.height) {
        CGFloat delta = self.userImageViewSize.height - frm.size.height;
        frm.size.height = self.userImageViewSize.height;
        
        for (UIView *sub in self.containerView.subviews) {
            CGRect fr = sub.frame;
            fr.origin.y += delta;
            sub.frame = fr;
        }
    }
    self.containerView.frame = frm;
    
    // Adjusing time label
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    self.timeLabel.frame = CGRectZero;
    self.timeLabel.text = [formatter stringFromDate:self.message.date];
    
    [self.timeLabel sizeToFit];
    CGRect timeLabel = self.timeLabel.frame;
    timeLabel.origin.x = self.contentView.frame.size.width + 5;
    self.timeLabel.frame = timeLabel;
    self.timeLabel.center = CGPointMake(self.timeLabel.center.x, self.containerView.center.y);
    
    if (self.backgroundImageView) {
        timeLabel.size.width += 10;
        timeLabel.size.height += 5;
        self.backgroundImageView.frame = timeLabel;
        self.backgroundImageView.center = self.timeLabel.center;
    }
}

- (CGRect)usedRectForWidth:(CGFloat)width
{
    CGRect usedFrame = CGRectZero;
    
    if (self.message.attributes) {
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:self.message.body
                                                                             attributes:self.message.attributes];
        self.textView.attributedText = attributedText;
        usedFrame.size = [self.message.body usedSizeForMaxWidth:width
                                                 withAttributes:self.message.attributes];
    } else {
        self.textView.text = self.message.body;
        usedFrame.size = [self.message.body usedSizeForMaxWidth:width
                                                       withFont:self.messageFont];
    }
    
    return usedFrame;
}

- (void)adjustForPhotoOnly
{
    CGRect frame = CGRectZero;

    [self adjustMediaImageViewWithFrame:&frame];
    [self adjustProgressViewWithFrame:frame];
    [self adjustBalloonImageViewWithFrame:frame];
    [self adjustUserImageView:frame];
    [self adjustContainerViewWithFrame:frame];
    [self maskMediaImageView];
    [self adjustTimeLabel];
}

-(void) adjustMediaImageViewWithFrame:(CGRect *) frame
{
    CGRect newFrame = *frame;

    UIImage *placeholder = self.message.media ? [[UIImage alloc] initWithData:self.message.media] : [UIImage imageNamed:@"messageplaceholder"];

    if (self.message.preview) {
        [self.mediaImageView sd_setImageWithURL:[NSURL URLWithString:self.message.preview]
                               placeholderImage:placeholder];
    }
    else {
        self.mediaImageView.image = placeholder;
    }

    newFrame.size = self.mediaImageViewSize;

    if (!self.message.fromMe && self.userImage) {
        newFrame.origin.x += userImageSideMargin + self.userImageViewSize.width;
    }

    self.mediaImageView.frame = newFrame;
    *frame = newFrame;
}

-(void) adjustBalloonImageViewWithFrame:(CGRect) frame
{
    self.balloonImageView.frame = frame;
    self.balloonImageView.backgroundColor = [UIColor clearColor];
    self.balloonImageView.image = self.balloonImage;
}

-(void) adjustUserImageView:(CGRect) frame
{
    CGRect userRect = self.userImageView.frame;

    if (self.userImageView.autoresizingMask & UIViewAutoresizingFlexibleTopMargin) {
        userRect.origin.y = frame.origin.y + frame.size.height - userRect.size.height;
    } else {
        userRect.origin.y = 0;
    }

    if (self.message.fromMe) {
        userRect.origin.x = frame.origin.x + userImageSideMargin + frame.size.width;
    } else {
        userRect.origin.x = frame.origin.x - userImageSideMargin - userRect.size.width;
    }
    self.userImageView.frame = userRect;
    self.userImageView.image = self.userImage;
}

-(void) adjustContainerViewWithFrame:(CGRect) frame
{
    CGRect userRect = self.userImageView.frame;

    CGRect frm = self.containerView.frame;
    frm.origin.x = self.message.fromMe ? self.contentView.frame.size.width - frame.size.width - bubbleRightMargin : bubbleLeftMargin;
    frm.origin.y = kBubbleTopMargin;
    frm.size.width = frame.size.width;
    if (!CGSizeEqualToSize(userRect.size, CGSizeZero) && self.userImage) {
        self.userImageView.hidden = NO;
        frm.size.width += userImageSideMargin + userRect.size.width;
        if (self.message.fromMe) {
            frm.origin.x -= userImageSideMargin + userRect.size.width;
        }
    }

    frm.size.height = frame.size.height;
    if (frm.size.height < self.userImageViewSize.height) {
        CGFloat delta = self.userImageViewSize.height - frm.size.height;
        frm.size.height = self.userImageViewSize.height;

        for (UIView *sub in self.containerView.subviews) {
            CGRect fr = sub.frame;
            fr.origin.y += delta;
            sub.frame = fr;
        }
    }
    self.containerView.frame = frm;
}

-(void) adjustProgressViewWithFrame:(CGRect) frame
{
    self.progressView = nil;
    if (self.message.isUploading) {
        self.progressView = [[DAProgressOverlayView alloc] initWithFrame:frame];
        [self.mediaImageView addSubview:self.progressView];

        if (self.message.progress == 0) {
            [self.progressView displayOperationWillTriggerAnimation];
        }

        if (self.message.progress < 1) {
            self.progressView.progress = self.message.progress;
        }
        else if (self.message.isUploading) {
            [self.progressView displayOperationDidFinishAnimation];
            double delayInSeconds = self.progressView.stateChangeAnimationDuration;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
                self.message.isUploading = NO;
                [self.progressView removeFromSuperview];
                self.mediaImageView.alpha = 0.8;
            });
        }
    }
    else if (self.message.progress == 0) {
        self.mediaImageView.alpha = 1;
        self.message.progress = 0;
    }
    else {
        self.mediaImageView.alpha = 0.8;
    }
}

-(void) maskMediaImageView
{
    CALayer *layer = self.balloonImageView.layer;
    layer.frame    = (CGRect){{0,0}, self.balloonImageView.layer.frame.size};
    self.mediaImageView.layer.mask = layer;
    [self.mediaImageView setNeedsDisplay];
}

-(void) adjustTimeLabel
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    self.timeLabel.frame = CGRectZero;
    self.timeLabel.text = [formatter stringFromDate:self.message.date];

    [self.timeLabel sizeToFit];
    CGRect timeLabel = self.timeLabel.frame;
    timeLabel.origin.x = self.contentView.frame.size.width + 5;
    self.timeLabel.frame = timeLabel;
    self.timeLabel.center = CGPointMake(self.timeLabel.center.x, self.containerView.center.y);

    if (self.backgroundImageView) {
        timeLabel.size.width += 10;
        timeLabel.size.height += 5;
        self.backgroundImageView.frame = timeLabel;
        self.backgroundImageView.center = self.timeLabel.center;
    }
}

- (void)adjustForVideoOnly
{
    [self adjustForPhotoOnly];
    [self setupMediaOverlayView];
    [self.mediaOverlayView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self addDimmedView];
    [self addPlayButton];
}

-(void) setupMediaOverlayView
{
    CGRect frame = self.mediaOverlayView.frame;
    frame.origin = CGPointZero;
    frame.size   = self.mediaImageView.frame.size;
    self.mediaOverlayView.frame = frame;
}

-(void) addDimmedView
{
    UIView *bgView = [[UIView alloc] init];
    bgView.frame = self.mediaImageView.bounds;
    bgView.backgroundColor = [UIColor blackColor];
    bgView.alpha = 0.4f;
    [self.mediaOverlayView addSubview:bgView];
}

-(void) addPlayButton
{
    UIImageView *playButtonImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"play_button.png"]];
    playButtonImageView.contentMode = UIViewContentModeScaleAspectFit;
    playButtonImageView.clipsToBounds = YES;
    playButtonImageView.backgroundColor = [UIColor clearColor];
    CGRect playFrame = playButtonImageView.frame;
    playFrame.size   = CGSizeMake(20, 20);
    playButtonImageView.frame = playFrame;
    playButtonImageView.center = CGPointMake(self.mediaOverlayView.frame.size.width/2 + self.contentInsets.left - self.contentInsets.right, self.mediaOverlayView.frame.size.height/2);
    [self.mediaOverlayView addSubview:playButtonImageView];
}

#pragma mark - GestureRecognizer delegates
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    
    CGPoint velocity = [self.panGesture velocityInView:self.panGesture.view];
    if (self.panGesture.state == UIGestureRecognizerStateBegan) {
        isHorizontalPan = fabs(velocity.x) > fabs(velocity.y);
    }
    
    return !isHorizontalPan;
}

#pragma mark -
- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    CGPoint velocity = [pan velocityInView:pan.view];
    
    if (pan.state == UIGestureRecognizerStateBegan) {
        isHorizontalPan = fabs(velocity.x) > fabs(velocity.y);
        
        if (!cellIsDragging) {
            initialTimeLabelPosX = self.timeLabel.frame.origin.x;
        }
    }
    
    if (isHorizontalPan) {
        NSArray *visibleCells = [self.tableView visibleCells];
        
        if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
            cellIsDragging = NO;
            [UIView animateWithDuration:0.25 animations:^{
                [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
                for (SOMessageCell *cell in visibleCells) {
                    
                    contentOffsetX = 0;
                    CGRect frame = cell.contentView.frame;
                    frame.origin.x = contentOffsetX;
                    cell.contentView.frame = frame;
                    
                    if (!cell.message.fromMe) {
                        CGRect timeframe = cell.timeLabel.frame;
                        timeframe.origin.x = initialTimeLabelPosX;
                        cell.timeLabel.frame = timeframe;
                        if (cell.backgroundImageView) {
                            cell.backgroundImageView.center = cell.timeLabel.center;
                        }
                    }
                }
            }];
        } else {
            cellIsDragging = YES;
            
            CGPoint translation = [pan translationInView:pan.view];
            CGFloat delta = translation.x * (1 - fabs(contentOffsetX / maxContentOffsetX));
            contentOffsetX += delta;
            if (contentOffsetX > 0) {
                contentOffsetX = 0;
            }
            if (fabs(contentOffsetX) > fabs(maxContentOffsetX)) {
                contentOffsetX = -fabs(maxContentOffsetX);
            }
            for (SOMessageCell *cell in visibleCells) {
                if (cell.message.fromMe) {
                    CGRect frame = cell.contentView.frame;
                    frame.origin.x = contentOffsetX;
                    cell.contentView.frame = frame;
                } else {
                    CGRect frame = cell.timeLabel.frame;
                    frame.origin.x = initialTimeLabelPosX - fabs(contentOffsetX);
                    cell.timeLabel.frame = frame;
                    if (cell.backgroundImageView) {
                        cell.backgroundImageView.center = cell.timeLabel.center;
                    }
                }
            }
        }
    }
    
    [pan setTranslation:CGPointZero inView:pan.view];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    CGRect frame = self.contentView.frame;
    frame.origin.x = contentOffsetX;
    self.contentView.frame = frame;
}

- (void)handleOrientationWillChandeNote:(NSNotification *)note
{
    self.panGesture.enabled = NO;
    self.panGesture.enabled = YES;
}

#pragma mark - Getters and Setters
+ (CGFloat) messageTopMargin
{
    return messageTopMargin;
}

+ (void) setMessageTopMargin:(CGFloat)margin
{
    messageTopMargin = margin;
}

+ (CGFloat) messageBottomMargin;
{
    return messageBottomMargin;
}

+ (void) setMessageBottomMargin:(CGFloat)margin
{
    messageBottomMargin = margin;
}

+ (CGFloat) messageLeftMargin
{
    return messageLeftMargin;
}

+ (void) setMessageLeftMargin:(CGFloat)margin
{
    messageLeftMargin = margin;
}

+ (CGFloat) messageRightMargin
{
    return messageRightMargin;
}

+ (void) setMessageRightMargin:(CGFloat)margin
{
    messageRightMargin = margin;
}

+ (void) setBubbleRightMargin: (CGFloat)margin
{
    bubbleRightMargin = margin;
}

+ (void) setBubbleLeftMargin: (CGFloat)margin
{
    bubbleLeftMargin = margin;
}

+ (void) setUserImageSideMargin:(CGFloat)margin
{
    userImageSideMargin = margin;
}

+ (CGFloat)maxContentOffsetX
{
    return maxContentOffsetX;
}

+ (void)setMaxContentOffsetX:(CGFloat)offsetX
{
    maxContentOffsetX = offsetX;
}

#pragma mark -
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
