//
//  MALabel.h
//  MALabel
//
//  Created by admin on 2017/11/29.
//  Copyright © 2017年 ma. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSAttributedStringKey _Nonnull const MALinkAttributeName;
UIKIT_EXTERN NSAttributedStringKey  _Nonnull const MALinkTextTouchAttributesName;
UIKIT_EXTERN NSAttributedStringKey  _Nonnull const MALinkTextAttributesName;

UIKIT_EXTERN NSAttributedStringKey  _Nonnull const MASuperLinkAttributeName;
UIKIT_EXTERN NSAttributedStringKey  _Nonnull const MASuperLinkTextTouchAttributesName;

typedef NS_ENUM(NSUInteger, MALinkGestureRecognizerResult) {
    MALinkGestureRecognizerResultUnknown,
    MALinkGestureRecognizerResultTap,
    MALinkGestureRecognizerResultLongPress,
    MALinkGestureRecognizerResultFailed,
};

@class MALinkGestureRecognizer;
@interface MALabel : UITextView

- (instancetype _Nonnull)init NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithCoder:(NSCoder *_Nullable)coder NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *_Nullable)textContainer NS_UNAVAILABLE;

+ (instancetype _Nonnull)createLabel;

@property (nonatomic, copy) NSDictionary<NSAttributedStringKey, id> * _Nullable linkTextTouchAttributes;
@property (nonatomic, copy) NSDictionary<NSAttributedStringKey, id> * _Nullable superLinkTextTouchAttributes;

@property (nonatomic, assign) CFTimeInterval minimumPressDuration;

@property (nonatomic, assign) CGFloat allowableMovement;
// 点击高亮扩大的范围 默认:{-5, -5, -5, -5}
@property (nonatomic) UIEdgeInsets tapAreaInsets;

@property (nonatomic, readonly) MALinkGestureRecognizer * _Nullable linkGestureRecognizer;

@property (nonatomic, assign) CGFloat linkCornerRadius;

@property (nonatomic,copy) void (^ _Nullable linkLongPressBlock)(MALabel * _Nullable label, NSDictionary * _Nullable value);
@property (nonatomic,copy) void (^ _Nullable linkTapBlock)(MALabel * _Nullable label, NSDictionary * _Nullable value);

@property (nonatomic,copy) void (^ _Nullable commonTapBlock)(MALabel * _Nullable label);
@property (nonatomic,copy) void (^ _Nullable commonLongPressBlock)(MALabel * _Nullable label);

- (void)enumerateViewRectsForRanges:(NSArray *_Nullable)ranges usingBlock:(void (^_Nullable)(CGRect rect, NSRange range, BOOL * _Nullable stop))block;

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^_Nullable)(NSRange range, BOOL isSuperLink))block;

@end


@interface MALinkGestureRecognizer : UIGestureRecognizer

@property (nonatomic) CFTimeInterval minimumPressDuration;

@property (nonatomic) CGFloat allowableMovement;

@property (nonatomic, readonly) MALinkGestureRecognizerResult result;

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

#pragma mark - 便捷添加属性

/*
 添加点击属性
 
 @param attributeString 富文本
 @param userInfo 点击时的附加信息
 @param linkTextAttributes 点击内容的默认样式
 @param linkTextTouchAttributes 点击时的样式
 @param range 设置的范围
 */
+ (void)addLinkAttributeWithString:(NSMutableAttributedString *_Nullable)attributeString userInfo:(NSDictionary *_Nullable)userInfo linkTextAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextAttributes linkTextTouchAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextTouchAttributes range:(NSRange)range;

/*
 添加次优先级的点击属性

 @param attributeString 富文本
 @param userInfo 点击时的附加信息
 @param linkTextTouchAttributes 点击时的样式
 @param range 设置的范围
 */
+ (void)addSuperLinkAttributeWithString:(NSMutableAttributedString *_Nullable)attributeString userInfo:(NSDictionary *_Nullable)userInfo linkTextTouchAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextTouchAttributes range:(NSRange)range;

#pragma mark - 创建富文本
/**
 制作普通富文本
 
 @param string 内容
 @param font 字体
 @param color 文本颜色
 @param userInfo 需要附加的信息
 */
+ (NSMutableAttributedString *_Nonnull)attStringWithString:(NSString *_Nullable)string font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color  userInfo:(NSDictionary *_Nullable)userInfo;
/**
 制作图片富文本
 
 @param image 图片
 @param font 字体
 @param imageHeight 图片高度
 @param spacing 间距
 @param userInfo 附加信息
 */
+ (NSMutableAttributedString *_Nonnull)attStringWithImage:(UIImage *_Nullable)image font:(UIFont *_Nullable)font imageHeight:(CGFloat)imageHeight spacing :(CGFloat)spacing spacingAddLeft:(BOOL)spacingAddLeft userInfo:(NSDictionary * _Nullable)userInfo;
/// 图片高度为font.pointSize
+ (NSMutableAttributedString *_Nonnull)attStringWithImage:(UIImage *_Nullable)image font:(UIFont *_Nullable)font spacing:(CGFloat)spacing spacingAddLeft:(BOOL)spacingAddLeft userInfo:(NSDictionary * _Nullable)userInfo;
/**
 *  自定义匹配电话,url,http,a标签
 *
 *  @param string    内容
 *  @param optional  要解析的方式
 *  @param font      字体
 *  @param color 文本颜色
 */
+ (NSMutableAttributedString *_Nonnull)attributedString:(NSString *_Nullable)string labelHelpHandle:(MALabelHelpHandle)optional font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color;

+ (NSMutableAttributedString *_Nullable)matchingWithRegular:(NSRegularExpression *_Nullable)regular attributeString:(NSMutableAttributedString *_Nullable)attributeString mapHandle:(NSAttributedString * _Nullable (^_Nullable)(NSArray * _Nullable results))mapHandle;

+ (NSMutableDictionary *_Nonnull)userInfoWithType:(NSUInteger)linkType title:(NSString *_Nullable)title key:(NSString *_Nullable)key;

+ (NSMutableAttributedString *_Nullable)attributedBracketString:(NSString *_Nullable)string font:(UIFont *_Nullable)font color:(UIColor *_Nullable)color block:(void(^_Nullable)(NSMutableAttributedString * _Nullable attributedString, NSDictionary * _Nonnull userInfo))block;


@end

@interface MASafeTimer : NSObject

+ (NSTimer *_Nullable)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id _Nullable )target selector:(SEL _Nullable )aSelector userInfo:(id _Nullable )userInfo repeats :(BOOL)repeats;
+ (NSTimer *_Nullable)timerWithTimeInterval:(NSTimeInterval)interval target:(id _Nullable )target selector:(SEL _Nullable )aSelector userInfo:(nullable id)userInfo repeats:(BOOL)repeats;

@end

@interface NSMutableAttributedString(MALabel)

- (NSMutableAttributedString *_Nonnull)ma_setParagraphStyleBlock:(void(^_Nonnull)(NSMutableParagraphStyle * _Nonnull style))styleBlock;

@end


@interface NSAttributedString(MALabel)

- (NSRange)allRange;

@end
