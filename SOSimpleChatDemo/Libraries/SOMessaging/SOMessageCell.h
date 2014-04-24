//
//  SOMessageCell.h
//  SOSimpleChatDemo
//
//  Created by Artur Mkrtchyan on 4/23/14.
//  Copyright (c) 2014 SocialOjbects Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOMessage.h"

#define kBubbleTopMargin 0
#define kBubbleLeftMargin 5
#define kBubbleRightMargin 5
#define kBubbleBottomMargin 10
#define kMessageMargin 10

@class SOMessageCell;
@protocol SOMessageCellDelegate <NSObject>

@optional
- (void)messageCell:(SOMessageCell *)cell didTapMedia:(NSData *)media;

@end

@interface SOMessageCell : UITableViewCell

@property (weak, nonatomic) SOMessage *message;
@property (weak, nonatomic) UIImage *balloonImage;
@property (strong, nonatomic) UIFont *messageFont;


@property (strong, nonatomic) UIImageView *userImageView;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *mediaImageView;

@property (strong, nonatomic) UIImageView *balloonImageView;

@property (nonatomic) CGFloat messageMaxWidth;

@property (strong, nonatomic) UIView *containerView;

@property (weak, nonatomic) id<SOMessageCellDelegate> delegate;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier messageMaxWidth:(CGFloat)messageMaxWidth;
- (void)setMediaImageViewSize:(CGSize)size;

- (void)adjustCell;

@end