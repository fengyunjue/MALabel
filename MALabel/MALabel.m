//
//  MALabel.m
//  MALabel
//
//  Created by admin on 2017/11/29.
//  Copyright © 2017年 ma. All rights reserved.
//

#import "MALabel.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

NSAttributedStringKey const MALinkAttributeName = @"MALinkAttributeName";
NSAttributedStringKey const MALinkTextTouchAttributesName = @"MALinkTextTouchAttributesName";
NSAttributedStringKey const MALinkTextAttributesName = @"MALinkTextAttributesName";

NSAttributedStringKey const MASuperLinkAttributeName = @"MASuperLinkAttributeName";
NSAttributedStringKey const MASuperLinkTextTouchAttributesName = @"MASuperLinkTextTouchAttributesName";


@interface MALabel()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray <NSDictionary *>*rangeValuesForTouchDown;
@property (nonatomic, strong) MALinkGestureRecognizer *linkGestureRecognizer;

@end

@implementation MALabel

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder{
    self = [super initWithCoder:coder];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp{
    self.backgroundColor = [UIColor clearColor];
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.scrollEnabled = NO;
    self.editable = NO;
    
    self.linkTextTouchAttributes = @{NSBackgroundColorAttributeName : UIColor.lightGrayColor};
    self.superLinkTextTouchAttributes = @{NSBackgroundColorAttributeName : UIColor.lightGrayColor};
    self.tapAreaInsets = UIEdgeInsetsMake(-5, -5, -5, -5);
}

- (void)drawRoundedCornerForRange:(NSRange)range{
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = self.bounds;
    layer.backgroundColor = [[UIColor clearColor] CGColor];
    
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
    CGContextFillRect(context, layer.bounds); // Unmask the whole text area
    
    NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
    [self.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:self.textContainer usingBlock:^(CGRect rect, BOOL *stop) {
        rect.origin.x += self.textContainerInset.left - self.contentOffset.x;
        rect.origin.y += self.textContainerInset.top - self.contentOffset.y;
        
        CGContextClearRect(context, CGRectInset(rect, -1, -1)); // Mask the rectangle of the range
        
        CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:self.linkCornerRadius].CGPath);
        CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);  // Unmask the rounded area inside the rectangle
        CGContextFillPath(context);
    }];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [layer setContents:(id)[image CGImage]];
    self.layer.mask = layer;
}

#pragma mark 遍历方法
- (void)enumerateViewRectsForRanges:(NSArray *)ranges usingBlock:(void (^)(CGRect rect, NSRange range, BOOL *stop))block{
    if (!block) return;
    
    for (NSValue *rangeAsValue in ranges) {
        NSRange range = rangeAsValue.rangeValue;
        NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
        [self.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:self.textContainer usingBlock:^(CGRect rect, BOOL *stop) {
            rect.origin.x += self.textContainerInset.left;
            rect.origin.y += self.textContainerInset.top;
            rect = UIEdgeInsetsInsetRect(rect, self.tapAreaInsets);
            
            block(rect, range, stop);
        }];
    }
}

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^)(NSRange range, BOOL isSuperLink))block{
    __block BOOL found = NO;
    
    NSAttributedString *attributedString = self.attributedText;
    [attributedString enumerateAttribute:MALinkAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (found) {
            *stop = YES;
            return;
        }
        if (value) {
            [self enumerateViewRectsForRanges:@[[NSValue valueWithRange:range]] usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
                if (found) {
                    *stop = YES;
                    return;
                }
                if (CGRectContainsPoint(rect, location)) {
                    found = YES;
                    *stop = YES;
                    if (block) {
                        block(range, NO);
                    }
                }
            }];
        }
    }];
    if (found == NO) {
        [attributedString enumerateAttribute:MASuperLinkAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
            if (found) {
                *stop = YES;
                return;
            }
            if (value) {
                [self enumerateViewRectsForRanges:@[[NSValue valueWithRange:range]] usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
                    if (found) {
                        *stop = YES;
                        return;
                    }
                    if (CGRectContainsPoint(rect, location)) {
                        found = YES;
                        *stop = YES;
                        if (block) {
                            block(range, YES);
                        }
                    }
                }];
            }
        }];
    }
    
    return found;
}

#pragma mark Gesture recognition

- (void)linkAction:(MALinkGestureRecognizer *)recognizer{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSAssert(self.rangeValuesForTouchDown == nil, @"Invalid touch down ranges");
        
        CGPoint location = [recognizer locationInView:self];
        self.rangeValuesForTouchDown = [self didTouchDownAtLocation:location];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSAssert(self.rangeValuesForTouchDown != nil, @"Invalid touch down ranges");
        
        if (recognizer.result == MALinkGestureRecognizerResultTap) {
            [self didTapAtRangeValues:self.rangeValuesForTouchDown];
        } else if (recognizer.result == MALinkGestureRecognizerResultLongPress) {
            [self didLongPressAtRangeValues:self.rangeValuesForTouchDown];
        }
        
        [self didCancelTouchDownAtRangeValues:self.rangeValuesForTouchDown];
        self.rangeValuesForTouchDown = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}

#pragma mark Gesture handling

- (NSArray <NSDictionary *>*)didTouchDownAtLocation:(CGPoint)location{
    NSMutableArray *rangeValuesForTouchDown = [NSMutableArray array];
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range, BOOL isSuperLink) {
        [rangeValuesForTouchDown addObject:@{@"range":[NSValue valueWithRange:range],@"isSuperLink":@(isSuperLink)}];
        
        NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
        
        if (isSuperLink) {
            NSDictionary *superLinkTextTouchAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MASuperLinkTextTouchAttributesName]?:self.superLinkTextTouchAttributes;
             if (superLinkTextTouchAttributes) {
                 [attributedText addAttributes:superLinkTextTouchAttributes range:range];
             }
        }else{
            NSDictionary *linkTextAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MALinkTextAttributesName]?:self.linkTextAttributes;
            NSDictionary *linkTextTouchAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MALinkTextTouchAttributesName]?:self.linkTextTouchAttributes;
             
             for (NSString *attribute in linkTextAttributes) {
                 [attributedText removeAttribute:attribute range:range];
             }
             if (linkTextTouchAttributes) {
                 [attributedText addAttributes:linkTextTouchAttributes range:range];
             }
        }
        [super setAttributedText:attributedText];
        
        if (self.linkCornerRadius > 0) {
            [self drawRoundedCornerForRange:range];
        }
    }];
    
    return rangeValuesForTouchDown;
}

- (void)didCancelTouchDownAtRangeValues:(NSArray *)rangeValues{
    NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
    for (NSDictionary *value in rangeValues) {
        NSRange range = [value[@"range"] rangeValue];
        BOOL isSuperLink = [value[@"isSuperLink"] boolValue];
        
        if (isSuperLink) {
            NSDictionary *superLinkTextTouchAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MASuperLinkTextTouchAttributesName]?:self.superLinkTextTouchAttributes;
            for (NSString *attribute in superLinkTextTouchAttributes) {
                [attributedText removeAttribute:attribute range:range];
            }
        }else{
            NSDictionary *linkTextAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MALinkTextAttributesName]?:self.linkTextAttributes;
            NSDictionary *linkTextTouchAttributes = [MALabel linkeAttributesWithAttributedText:attributedText range:range attributesName:MALinkTextTouchAttributesName] ?:self.linkTextTouchAttributes;
            
            for (NSString *attribute in linkTextTouchAttributes) {
                [attributedText removeAttribute:attribute range:range];
            }
            if (linkTextAttributes) {
                [attributedText addAttributes:linkTextAttributes range:range];
            }
        }
    }
    [super setAttributedText:attributedText];
    self.layer.mask = nil;
}

- (void)didTapAtRangeValues:(NSArray *)rangeValues{
    if (rangeValues.count > 0 && self.linkTapBlock) {
        for (NSDictionary *value in rangeValues) {
            NSRange range = [value[@"range"] rangeValue];
            BOOL isSuperLink = [value[@"isSuperLink"] boolValue];
            if (range.location < self.attributedText.length) {
                id value = [self.attributedText attribute:isSuperLink ? MASuperLinkAttributeName : MALinkAttributeName atIndex:range.location effectiveRange:NULL];
                self.linkTapBlock(self, value);
            }else if (self.commonTapBlock){
                self.commonTapBlock(self);
            }
        }
    }else if (rangeValues.count == 0 && self.commonTapBlock){
        self.commonTapBlock(self);
    }
}

- (void)didLongPressAtRangeValues:(NSArray *)rangeValues{
    if (rangeValues.count > 0 && self.linkLongPressBlock) {
        for (NSDictionary *value in rangeValues) {
            NSRange range = [value[@"range"] rangeValue];
            BOOL isSuperLink = [value[@"isSuperLink"] boolValue];
            if (range.location < self.attributedText.length) {
                id value = [self.attributedText attribute:isSuperLink ? MASuperLinkAttributeName : MALinkAttributeName atIndex:range.location effectiveRange:NULL];
                self.linkLongPressBlock(self, value);
            }else if (self.commonLongPressBlock){
                self.commonLongPressBlock(self);
            }
        }
    }else if (rangeValues.count == 0 && self.commonLongPressBlock){
        self.commonLongPressBlock(self);
    }
}

#pragma mark - 属性处理
- (void)setEditable:(BOOL)editable{
    super.editable = editable;
    if (editable) {
        self.selectable = YES;
        [self removeGestureRecognizer:self.linkGestureRecognizer];
    } else {
        self.selectable = NO;
        if (![self.gestureRecognizers containsObject:self.linkGestureRecognizer]) {
            self.linkGestureRecognizer = [[MALinkGestureRecognizer alloc] initWithTarget:self action:@selector(linkAction:)];
            self.linkGestureRecognizer.delegate = self;
            [self addGestureRecognizer:self.linkGestureRecognizer];
        }
    }
}

- (void)setLinkTextAttributes:(NSDictionary *)linkTextAttributes{
    [super setLinkTextAttributes:linkTextAttributes];
    [self setAttributedText:self.attributedText];
}

- (void)setLinkTextTouchAttributes:(NSDictionary *)linkTextTouchAttributes{
    _linkTextTouchAttributes = linkTextTouchAttributes;
    [self setAttributedText:self.attributedText];
}

- (void)setAttributedText:(NSAttributedString *)attributedText{
    NSMutableAttributedString *mutableAttributedText = [attributedText mutableCopy];
    [mutableAttributedText enumerateAttribute:MALinkAttributeName inRange:NSMakeRange(0, attributedText.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            NSDictionary *linkTextAttributes = [MALabel linkeAttributesWithAttributedText:mutableAttributedText range:range attributesName:MALinkTextAttributesName] ?: self.linkTextAttributes;
            if (linkTextAttributes) {
                [mutableAttributedText addAttributes:linkTextAttributes range:range];
            }
        }
    }];
    [super setAttributedText:mutableAttributedText];
}

- (void)setMinimumPressDuration:(CFTimeInterval)minimumPressDuration{
    self.linkGestureRecognizer.minimumPressDuration = minimumPressDuration;
}

- (CFTimeInterval)minimumPressDuration{
    return self.linkGestureRecognizer.minimumPressDuration;
}

- (void)setAllowableMovement:(CGFloat)allowableMovement{
    self.linkGestureRecognizer.allowableMovement = allowableMovement;
}

- (CGFloat)allowableMovement{
    return self.linkGestureRecognizer.allowableMovement;
}

+ (NSDictionary *)linkeAttributesWithAttributedText:(NSAttributedString *)attributedText range:(NSRange)range attributesName:(NSString *)attributesName {
    if (attributedText == nil || attributedText.length < range.location + range.length || attributesName == nil) {
        return nil;
    }
    NSDictionary *dict = [attributedText attributesAtIndex:range.location longestEffectiveRange:nil inRange:range][attributesName];
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        return dict;
    }
    return nil;
}

@end





@interface MALinkGestureRecognizer ()

@property (nonatomic) MALinkGestureRecognizerResult result;
@property (nonatomic) CGPoint initialPoint;
@property (nonatomic) NSTimer *timer;

@end

@implementation MALinkGestureRecognizer

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

- (instancetype)initWithTarget:(id)target action:(SEL)action{
    self = [super initWithTarget:target action:action];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp{
    // Same defaults as UILongPressGestureRecognizer
    self.minimumPressDuration = 0.5;
    self.allowableMovement = 10;
    
    self.result = MALinkGestureRecognizerResultUnknown;
    self.initialPoint = CGPointZero;
}

- (void)reset{
    [super reset];
    
    self.result = MALinkGestureRecognizerResultUnknown;
    self.initialPoint = CGPointZero;
    [self.timer invalidate];
    self.timer = nil;
}

- (void)longPressed:(NSTimer *)timer{
    [timer invalidate];
    
    self.result = MALinkGestureRecognizerResultLongPress;
    self.state = UIGestureRecognizerStateRecognized;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    
    NSAssert(self.result == MALinkGestureRecognizerResultUnknown, @"Invalid result state");
    
    UITouch *touch = touches.anyObject;
    self.initialPoint = [touch locationInView:self.view];
    self.state = UIGestureRecognizerStateBegan;
    
    self.timer = [MASafeTimer scheduledTimerWithTimeInterval:self.minimumPressDuration target:self selector:@selector(longPressed:) userInfo:nil repeats:NO];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesMoved:touches withEvent:event];
    
    if (![self touchIsCloseToInitialPoint:touches.anyObject]) {
        self.result = MALinkGestureRecognizerResultFailed;
        self.state = UIGestureRecognizerStateRecognized;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    
    if ([self touchIsCloseToInitialPoint:touches.anyObject]) {
        self.result = MALinkGestureRecognizerResultTap;
        self.state = UIGestureRecognizerStateRecognized;
    } else {
        self.result = MALinkGestureRecognizerResultFailed;
        self.state = UIGestureRecognizerStateRecognized;
    }
}

- (BOOL)touchIsCloseToInitialPoint:(UITouch *)touch{
    CGPoint point = [touch locationInView:self.view];
    CGFloat xDistance = (self.initialPoint.x - point.x);
    CGFloat yDistance = (self.initialPoint.y - point.y);
    CGFloat squaredDistance = (xDistance * xDistance) + (yDistance * yDistance);
    
    BOOL isClose = (squaredDistance <= (self.allowableMovement * self.allowableMovement));
    return isClose;
}

@end

@implementation MAContentLabelHelp

#pragma mark - 便捷添加属性

/// 添加点击属性
+ (void)addLinkAttributeWithString:(NSMutableAttributedString *_Nullable)attributeString userInfo:(NSDictionary *_Nullable)userInfo linkTextAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextAttributes linkTextTouchAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextTouchAttributes range:(NSRange)range {
    if (attributeString == nil || attributeString.length < range.location + range.length) { return; }
    if (userInfo) {
        [attributeString addAttribute:MALinkAttributeName value:userInfo range:range];
    }
    if (linkTextAttributes) {
        [attributeString addAttribute:MALinkTextAttributesName value:linkTextAttributes range:range];
    }
    if (linkTextTouchAttributes) {
        [attributeString addAttribute:MALinkTextTouchAttributesName value:linkTextTouchAttributes range:range];
    }
}

/// 添加次优先级的点击属性
+ (void)addSuperLinkAttributeWithString:(NSMutableAttributedString *_Nullable)attributeString userInfo:(NSDictionary *_Nullable)userInfo linkTextTouchAttributes:(NSDictionary<NSAttributedStringKey, id> *_Nullable)linkTextTouchAttributes range:(NSRange)range {
    if (attributeString == nil || attributeString.length < range.location + range.length) { return; }
    if (userInfo) {
        [attributeString addAttribute:MASuperLinkAttributeName value:userInfo range:range];
    }
    if (linkTextTouchAttributes) {
        [attributeString addAttribute:MASuperLinkTextTouchAttributesName value:linkTextTouchAttributes range:range];
    }
}

#pragma mark - 创建富文本

+ (NSMutableAttributedString *)attributedString:(NSString *)string labelHelpHandle:(MALabelHelpHandle)optional font:(UIFont *)font color:(UIColor *)color{
    if (string.length == 0) return [self attStringWithString:@" " font:font color:color userInfo:nil];
    
    [self regexInitialization];
    
    NSMutableAttributedString *text = [self attStringWithString:string font:font color:color userInfo:nil];
    __weak typeof(self)weakSelf = self;
    // 匹配过滤br标签
    text = [self matchingWithRegular:regexBr attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        if (results.count != 1) return nil;
        return [weakSelf attStringWithString:@"\n" font:font color:color userInfo:nil];
    }];
    // 匹配过滤p标签
    text = [self matchingWithRegular:regexP attributeString:text mapHandle:^NSAttributedString *(NSArray <NSString *>*results) {
        if (results.count != 3) return nil;
        return [weakSelf attStringWithString:[NSString stringWithFormat:@"%@%@",results[1], [results[2] isEqualToString:@"\n"] ? @"" : @"\n"] font:font color:color userInfo:nil];
    }];
    
    if (optional&MALabelHelpHandleATag) {
        // 匹配 atag
        text = [self matchingWithRegular:regexAtagFormat attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 3) return nil;
            NSString *href = results[1];
            NSString *title = results[2];
            return [weakSelf attStringWithString:title font:font color:color userInfo:[weakSelf userInfoWithType:[title isEqualToString:@"[图片]"] ? kMALinkTypeImg : kMALinkTypeURL title:title key:href]];
        }];
    }
    
    if (optional&MALabelHelpHandleImg) {
        // 匹配img
        text = [self matchingWithRegular:regexImg attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 2) return nil;
            NSString *imgStr = results[1];
            NSString *title = @"[图片]";
            return [weakSelf attStringWithString:title font:font color:color userInfo:[weakSelf userInfoWithType:kMALinkTypeImg title:title key:imgStr]];
        }];
    }
    
    if (optional&MALabelHelpHandleHttp) {
        // 匹配 http
        text = [self matchingWithRegular:regexHttp attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count == 0) return nil;
            NSString *httpStr = results[0];
            return [weakSelf attStringWithString:httpStr font:font color:color userInfo:[weakSelf userInfoWithType:kMALinkTypeURL title:httpStr key:httpStr]];
        }];
    }
    
    if (optional&MALabelHelpHandlePhone) {
        // 匹配phone
        text = [self matchingWithRegular:regexPhone attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 1) return nil;
            NSString *phoneStr = results[0];
            return [weakSelf attStringWithString:phoneStr font:font color:color userInfo:[weakSelf userInfoWithType:kMALinkTypePhone title:phoneStr key:phoneStr]];
        }];
    }
    // 匹配过滤其他标签和尾部的换行以及尾部的&nbsp;
    text = [self matchingWithRegular:regexOther attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        return [weakSelf attStringWithString:@"" font:font color:color userInfo:nil];
    }];
    // 匹配&nbsp;
    text = [self matchingWithRegular:regexNBSP attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        if (results.count != 1) return nil;
        return [weakSelf attStringWithString:@" " font:font color:color userInfo:nil];
    }];
    return text;
}

/**
 *  制作高亮的富文本
 *
 *  @param string   文本
 *  @param userInfo 携带信息
 */
+ (NSMutableAttributedString *)attStringWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color userInfo:(NSDictionary *)userInfo{
    if (string.length == 0) {string = @"";}
     NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    if (font){
         [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedString.length)];
    }
    if (color){
         [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedString.length)];
    }
    if (userInfo) {
        [attributedString addAttribute:MALinkAttributeName value:userInfo range:NSMakeRange(0, attributedString.length)];
    }
    return attributedString;
}

/**
 制作图片富文本
 */
+ (NSMutableAttributedString *)attStringWithImage:(UIImage *)image font:(UIFont *)font spacing:(CGFloat)spacing userInfo:(NSDictionary *)userInfo {
    return [self attStringWithImage:image font:font imageHeight:font.pointSize spacing:spacing userInfo:userInfo];
}

+ (NSMutableAttributedString *)attStringWithImage:(UIImage *)image font:(UIFont *)font imageHeight:(CGFloat)imageHeight spacing :(CGFloat)spacing userInfo:(NSDictionary * _Nullable)userInfo {
    if (image == nil || image.size.width == 0 || image.size.height == 0 || font == nil) {
        return [self attStringWithString:@" " font:font color:nil userInfo:nil];
    }
    CGFloat imageWidth = (image.size.width / image.size.height) * imageHeight;
    
    NSMutableAttributedString *textAttrStr = [[NSMutableAttributedString alloc] init];
    NSTextAttachment *attach = [[NSTextAttachment alloc] init];
    attach.image = image;
    CGFloat textPaddingTop = font.lineHeight - font.pointSize;
    attach.bounds = CGRectMake(0, -textPaddingTop - (imageHeight - font.pointSize)/2, imageWidth, imageHeight);
    NSMutableAttributedString *attachmentStr = [[NSMutableAttributedString alloc] initWithAttributedString:[NSAttributedString attributedStringWithAttachment:attach]];
    if (userInfo) {
        [attachmentStr addAttribute:MALinkAttributeName value:userInfo range:NSMakeRange(0, attachmentStr.length)];
    }
    [textAttrStr appendAttributedString:attachmentStr];
    if (spacing > 0) {
        [textAttrStr insertAttributedString:[[NSAttributedString alloc] initWithString:@" "] atIndex:0];
        [textAttrStr addAttribute:NSKernAttributeName value:@(spacing) range:NSMakeRange(0, 2)];
    }
    return textAttrStr;
}

static NSRegularExpression *regexBracket;
/// 匹配{1{}}或{{}}
+ (NSMutableAttributedString *)attributedBracketString:(NSString *)string font:(UIFont *)font color:(UIColor *)color block:(void (^)(NSMutableAttributedString * _Nullable, NSDictionary *))block {
    if (regexBracket == nil) {
        regexBracket = [NSRegularExpression regularExpressionWithPattern:@"\\{([0-9]*)\\{(.+?)\\}\\}" options:kNilOptions error:NULL];
    }
    NSMutableAttributedString *text = [self attStringWithString:string font:font color:color userInfo:nil];
    text = [self matchingWithRegular:regexBracket attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        if (results.count != 3) return nil;
        NSString *index = results[1];
        NSString *bracketStr = results[2];
        NSDictionary *userInfo = [MAContentLabelHelp userInfoWithType:index.integerValue title:bracketStr key:bracketStr];
        NSMutableAttributedString *attributedString = [MAContentLabelHelp attStringWithString:bracketStr font:font color:color userInfo:userInfo];
        if (block) { block(attributedString, userInfo); }
        return attributedString;
    }];
    return text;
}


#pragma mark userInfo制作
+ (NSMutableDictionary *)userInfoWithType:(NSUInteger)linkType title:(NSString *)title key:(NSString *)key{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@(linkType) forKey:MALinkType];
    [userInfo setObject:title?:@"" forKey:MALinkTitle];
    [userInfo setObject:key?:@"" forKey:MALinkKey];
    return userInfo;
}

#pragma mark - 正则表达式
static NSRegularExpression *regexAtagFormat;
static NSRegularExpression *regexHttp;
static NSRegularExpression *regexPhone;
static NSRegularExpression *regexImg;
static NSRegularExpression *regexBr;
static NSRegularExpression *regexP;
static NSRegularExpression *regexOther;
static NSRegularExpression *regexNBSP;

+ (void)regexInitialization{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 匹配a标签
        regexAtagFormat = [NSRegularExpression regularExpressionWithPattern:@"<a\\b[^>]+\\bhref\\s*=\\s*\"([^\"]*)\"[^>]*>([\\s\\S]*?)</a>" options:kNilOptions error:NULL];
        // 匹配http
        regexHttp = [NSRegularExpression regularExpressionWithPattern:@"([hH]ttp[s]{0,1})://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\-~!@#$%^&*+?:_/=<>.\',;]*)?" options:kNilOptions error:NULL];
        // 匹配手机号
        regexPhone = [NSRegularExpression regularExpressionWithPattern:@"1[0-9]{10}(?!\\d)" options:kNilOptions error:NULL];
        // 匹配img
        regexImg = [NSRegularExpression regularExpressionWithPattern:@"<img.*?src\\s*=\\s*\"(.*?)\".*?>" options:kNilOptions error:NULL];
        // 匹配br标签
        regexBr = [NSRegularExpression regularExpressionWithPattern:@"<br\\s{0,1}/?>" options:kNilOptions error:NULL];
        // 匹配p标签
        regexP = [NSRegularExpression regularExpressionWithPattern:@"<p>((.|\n)*?)</p>" options:kNilOptions error:NULL];
        // 匹配其他标签和尾部的换行,以及尾部的&nbsp;
        regexOther = [NSRegularExpression regularExpressionWithPattern:@"<[^>]+>|\n+$|(&nbsp;|\\s)+$" options:kNilOptions error:NULL];
        // 匹配&nbsp;
        regexNBSP = [NSRegularExpression regularExpressionWithPattern:@"&nbsp;" options:kNilOptions error:NULL];
    });
}

+ (NSMutableAttributedString *)matchingWithRegular:(NSRegularExpression *)regular attributeString:(NSMutableAttributedString *)attributeString mapHandle:(NSAttributedString * (^)(NSArray *results))mapHandle {
    NSArray *array = [regular matchesInString:attributeString.string options:kNilOptions range:NSMakeRange(0, attributeString.string.length)];
    NSUInteger offSet = 0;
    for (NSTextCheckingResult *value in array) {
        if (value.range.location == NSNotFound && value.range.length <= 1) continue;
        NSRange range = value.range;
        range.location += offSet;
        if ([self attribute:attributeString attributeName:MALinkAttributeName atIndex:range.location]) continue;
        
        NSMutableArray <NSString *>*results = [NSMutableArray array];
        for (NSInteger index = 0; index < value.numberOfRanges; index++) {
            NSRange ran = [value rangeAtIndex:index];
            NSString *str = nil;
            if (ran.location != NSNotFound) {
                ran.location += offSet;
                str = [attributeString.string substringWithRange:ran];
            }
            [results addObject:str?:@""];
        }
        NSAttributedString *replace = mapHandle(results);
        if (replace) {
            [attributeString replaceCharactersInRange:range withAttributedString:replace];
            offSet += replace.length - range.length;
        }
    }
    return attributeString;
}

+ (id)attribute:(NSAttributedString *)attribute attributeName:(NSString *)attributeName atIndex:(NSUInteger)index {
    if (!attributeName) return nil;
    if (index > attribute.length || attribute.length == 0) return nil;
    if (attribute.length > 0 && index == attribute.length) index--;
    return [attribute attribute:attributeName atIndex:index effectiveRange:NULL];
}

@end


@interface MASafeTimer ()

@property (nonatomic, assign) SEL selector;
@property (nonatomic, weak) NSTimer *timer;
@property (nonatomic, weak) id target;
@end

@implementation MASafeTimer

- (void)run:(NSTimer *)timer {
    if (!self.target) {
        [self.timer invalidate];
    }else {
        [self.target performSelector:self.selector withObject:timer.userInfo];
    }
    
}
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)aSelector userInfo:(nullable id)userInfo repeats:(BOOL)repeats {
    MASafeTimer *crTimer = [[MASafeTimer alloc] init];
    crTimer.target = target;
    crTimer.selector = aSelector;
    crTimer.timer = [NSTimer timerWithTimeInterval:interval target:crTimer selector:@selector(run:) userInfo:userInfo repeats:repeats];
    return crTimer.timer;
}
+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval target:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats :(BOOL)repeats {
    MASafeTimer *crTimer = [[MASafeTimer alloc] init];
    crTimer.target = target;
    crTimer.selector = aSelector;
    crTimer.timer = [NSTimer scheduledTimerWithTimeInterval:interval target:crTimer selector:@selector(run:) userInfo:userInfo repeats:repeats];
    return crTimer.timer;
}

@end


@implementation NSMutableAttributedString(Category)

- (void)ma_setParagraphStyleBlock:(void (^)(NSMutableParagraphStyle * _Nonnull))styleBlock {
    if (styleBlock) {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc]init];
        styleBlock(style);
        [self addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, self.length)];
    }
}

@end
