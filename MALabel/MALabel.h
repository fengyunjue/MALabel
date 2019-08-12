//
//  MALabel.h
//  MALabel
//
//  Created by admin on 2017/11/29.
//  Copyright © 2017年 ma. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * _Nonnull const MALinkAttributeName;

typedef NS_ENUM(NSUInteger, MALinkGestureRecognizerResult) {
    MALinkGestureRecognizerResultUnknown,
    MALinkGestureRecognizerResultTap,
    MALinkGestureRecognizerResultLongPress,
    MALinkGestureRecognizerResultFailed,
};

@class MALinkGestureRecognizer;
@interface MALabel : UITextView

@property (nonatomic, copy) NSDictionary<NSString *, id> * _Nullable linkTextTouchAttributes;

@property (nonatomic, assign) CFTimeInterval minimumPressDuration;

@property (nonatomic, assign) CGFloat allowableMovement;
// 点击高亮扩大的范围 默认:{-5, -5, -5, -5}
@property (nonatomic) UIEdgeInsets tapAreaInsets;

@property (nonatomic, readonly) MALinkGestureRecognizer * _Nullable linkGestureRecognizer;

@property (nonatomic, assign) CGFloat linkCornerRadius;

@property (nonatomic,copy) void (^ _Nullable linkLongPressBlock)(MALabel * _Nullable label, id _Nullable value);
@property (nonatomic,copy) void (^ _Nullable linkTapBlock)(MALabel * _Nullable label, id _Nullable value);

@property (nonatomic,copy) void (^ _Nullable commonTapBlock)(MALabel * _Nullable label);
@property (nonatomic,copy) void (^ _Nullable commonLongPressBlock)(MALabel * _Nullable label);

- (void)enumerateViewRectsForRanges:(NSArray *_Nullable)ranges usingBlock:(void (^_Nullable)(CGRect rect, NSRange range, BOOL * _Nullable stop))block;

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^_Nullable)(NSRange range))block;

@end


@interface MALinkGestureRecognizer : UIGestureRecognizer

@property (nonatomic) CFTimeInterval minimumPressDuration;

@property (nonatomic) CGFloat allowableMovement;

@property (nonatomic, readonly) MALinkGestureRecognizerResult result;

@end

@interface MATextAttachment : NSTextAttachment

@end

typedef NS_OPTIONS(NSInteger, MALabelHelpHandle) {
    MALabelHelpHandleATag    = 1 << 0,      // 匹配a标签[MALinkAtagFormatUrl][MALinkAtagFormatName]
    MALabelHelpHandleImg     = 1 << 1,      // 匹配http[kMALinkTypeImg]
    MALabelHelpHandleHttp    = 1 << 2,      // 匹配http[MALinkURLName]
    MALabelHelpHandlePhone   = 1 << 3,      // 匹配phone[MALinkPhoneName]
    MALabelHelpHandleAll = 15
};

typedef enum : NSUInteger {
    kMALinkTypeNone,         // 无
    kMALinkTypePhone,        // 电话
    kMALinkTypeURL,          // 链接
    kMALinkTypeImg,          // 图片
} kMALinkType;

static NSString * _Nonnull const MALinkTitle           = @"MALinkTitle";//title
static NSString * _Nonnull const MALinkType            = @"MALinkType";//类型
static NSString * _Nonnull const MALinkKey             = @"MALinkKey";//key
static NSString * _Nonnull const MALinkURL             = @"MALinkURL";//url

@interface MAContentLabelHelp : NSObject
/**
 *  制作文件点击文本
 *
 *  @param string    文件名称
 *  @param urlString 点击的url
 *  @param font      文本字体
 *  @param color  文本颜色
 */
+ (NSMutableAttributedString *_Nullable)documentStringWithString:(NSString *_Nullable)string urlString:(NSString *_Nullable)urlString font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;
/**
 *  聊天消息匹配电话,url,http,a标签
 *
 *  @param string    内容
 *  @param font      字体
 *  @param color 文本颜色
 */
+ (NSMutableAttributedString *_Nullable)baseMessageWithString:(NSString *_Nullable)string font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;
/**
 *  匹配电话,url,http,a标签
 *
 *  @param string    内容
 *  @param optional  要解析的方式
 *  @param font      字体
 *  @param color 文本颜色
 */
+ (NSMutableAttributedString *_Nullable)attributedString:(NSString *_Nullable)string labelHelpHandle:(MALabelHelpHandle)optional font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;
/**
 *  制作高亮富文本
 *
 *  @param string   内容
 *  @param userInfo 需要附加的信息
 *  @param font     字体
 *  @param color 文本颜色
 */
+ (NSMutableAttributedString *_Nullable)hightlightBorderWithString:(NSString *_Nullable)string userInfo:(NSDictionary *_Nullable)userInfo font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;

/**
 制作普通富文本
 
 @param string 内容
 @param font 字体
 @param color 文本颜色
 */
+ (NSMutableAttributedString *_Nullable)attStringWithString:(NSString *_Nullable)string font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;
@end
