//
//  MALabel.m
//  MALabel
//
//  Created by admin on 2017/11/29.
//  Copyright © 2017年 ma. All rights reserved.
//

#import "MALabel.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

NSString *const MALinkAttributeName = @"MALinkAttributeName";

@interface MALabel()<UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSArray *rangeValuesForTouchDown;
@property (nonatomic) MALinkGestureRecognizer *linkGestureRecognizer;

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

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^)(NSRange range))block{
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
                        block(range);
                    }
                }
            }];
        }
    }];
    
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

- (NSArray *)didTouchDownAtLocation:(CGPoint)location{
    NSMutableArray *rangeValuesForTouchDown = [NSMutableArray array];
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        [rangeValuesForTouchDown addObject:[NSValue valueWithRange:range]];
        
        NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
        for (NSString *attribute in self.linkTextAttributes) {
            [attributedText removeAttribute:attribute range:range];
        }
        [attributedText addAttributes:self.linkTextTouchAttributes range:range];
        [super setAttributedText:attributedText];
        
        if (self.linkCornerRadius > 0) {
            [self drawRoundedCornerForRange:range];
        }
    }];
    
    return rangeValuesForTouchDown;
}

- (void)didCancelTouchDownAtRangeValues:(NSArray *)rangeValues{
    NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
    for (NSValue *rangeValue in rangeValues) {
        NSRange range = rangeValue.rangeValue;
        
        for (NSString *attribute in self.linkTextTouchAttributes) {
            [attributedText removeAttribute:attribute range:range];
        }
        [attributedText addAttributes:self.linkTextAttributes range:range];
    }
    [super setAttributedText:attributedText];
    self.layer.mask = nil;
}

- (void)didTapAtRangeValues:(NSArray *)rangeValues{
    if (rangeValues.count > 0 && self.linkTapBlock) {
        for (NSValue *rangeValue in rangeValues) {
            NSRange range = rangeValue.rangeValue;
            if (range.location < self.attributedText.length) {
                id value = [self.attributedText attribute:MALinkAttributeName atIndex:range.location effectiveRange:NULL];
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
        for (NSValue *rangeValue in rangeValues) {
            NSRange range = rangeValue.rangeValue;
            if (range.location < self.attributedText.length) {
                id value = [self.attributedText attribute:MALinkAttributeName atIndex:range.location effectiveRange:NULL];
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
            [mutableAttributedText addAttributes:self.linkTextAttributes range:range];
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
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.minimumPressDuration target:self selector:@selector(longPressed:) userInfo:nil repeats:NO];
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


@implementation MATextAttachment

//重载此方法 使得图片的大小和行高是一样的。
- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex{
    return CGRectMake(0, 0, lineFrag.size.height, lineFrag.size.height);
}

@end


@implementation MAContentLabelHelp

+ (NSMutableAttributedString *)baseMessageWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color{
    return [self attributedString:string labelHelpHandle:MALabelHelpHandleATag|MALabelHelpHandleHttp|MALabelHelpHandlePhone|MALabelHelpHandleImg font:font color:color];
}

+ (NSMutableAttributedString *)documentStringWithString:(NSString *)string urlString:(NSString *)urlString font:(UIFont *)font color:(UIColor *)color{
    return [self hightlightBorderWithString:string userInfo:[self userInfoWithType:kMALinkTypeURL title:string key:urlString] font:font color:color];
}

+ (NSMutableAttributedString *)attributedString:(NSString *)string labelHelpHandle:(MALabelHelpHandle)optional font:(UIFont *)font color:(UIColor *)color{
    if (string.length == 0) return [self attStringWithString:@" " font:font color:color];
    
    [self regexInitialization];
    
    NSMutableAttributedString *text = [self attStringWithString:string font:font color:color];
    __weak typeof(self)weakSelf = self;
    // 匹配过滤br标签
    text = [self matchingWithRegular:regexBr attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        if (results.count != 1) return nil;
        return [weakSelf attStringWithString:@"\n" font:font color:color];
    }];
    // 匹配过滤p标签
    text = [self matchingWithRegular:regexP attributeString:text mapHandle:^NSAttributedString *(NSArray <NSString *>*results) {
        if (results.count != 3) return nil;
        return [weakSelf attStringWithString:[NSString stringWithFormat:@"%@%@",results[1], [results[2] isEqualToString:@"\n"] ? @"" : @"\n"] font:font color:color];
    }];
    
    if (optional&MALabelHelpHandleATag) {
        // 匹配 atag
        text = [self matchingWithRegular:regexAtagFormat attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 3) return nil;
            NSString *href = results[1];
            NSString *title = results[2];
            return [weakSelf hightlightBorderWithString:title userInfo:[weakSelf userInfoWithType:[title isEqualToString:@"[图片]"] ? kMALinkTypeImg : kMALinkTypeURL title:title key:href] font:font color:color];
        }];
    }
    
    if (optional&MALabelHelpHandleImg) {
        // 匹配img
        text = [self matchingWithRegular:regexImg attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 2) return nil;
            NSString *imgStr = results[1];
            NSString *title = @"[图片]";
            return [weakSelf hightlightBorderWithString:title userInfo:[weakSelf userInfoWithType:kMALinkTypeImg title:title key:imgStr] font:font color:color];
        }];
    }
    
    if (optional&MALabelHelpHandleHttp) {
        // 匹配 http
        text = [self matchingWithRegular:regexHttp attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count == 0) return nil;
            NSString *httpStr = results[0];
            return [weakSelf hightlightBorderWithString:httpStr userInfo:[weakSelf userInfoWithType:kMALinkTypeURL title:httpStr key:httpStr] font:font color:color];
        }];
    }
    
    if (optional&MALabelHelpHandlePhone) {
        // 匹配phone
        text = [self matchingWithRegular:regexPhone attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
            if (results.count != 1) return nil;
            NSString *phoneStr = results[0];
            return [weakSelf hightlightBorderWithString:phoneStr userInfo:[weakSelf userInfoWithType:kMALinkTypePhone title:phoneStr key:phoneStr] font:font color:color];
        }];
    }
    // 匹配过滤其他标签和尾部的换行以及尾部的&nbsp;
    text = [self matchingWithRegular:regexOther attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        return [weakSelf attStringWithString:@"" font:font color:color];
    }];
    // 匹配&nbsp;
    text = [self matchingWithRegular:regexNBSP attributeString:text mapHandle:^NSAttributedString *(NSArray *results) {
        if (results.count != 1) return nil;
        return [weakSelf attStringWithString:@" " font:font color:color];
    }];
    return text;
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
            if (ran.location != NSNotFound) {
                ran.location += offSet;
                NSString *str = [attributeString.string substringWithRange:ran];
                if (str.length > 0) {
                    [results addObject: str];
                }
            }
        }
        NSAttributedString *replace = mapHandle(results);
        if (replace) {
            [attributeString replaceCharactersInRange:range withAttributedString:replace];
            offSet += replace.length - range.length;
        }
    }
    return attributeString;
}


/**
 *  制作高亮的富文本
 *
 *  @param string   文本
 *  @param userInfo 携带信息
 */
+ (NSMutableAttributedString *)hightlightBorderWithString:(NSString *)string userInfo:(NSDictionary *)userInfo font:(UIFont *)font color:(UIColor *)color{
    if (string.length == 0) return [self attStringWithString:@" " font:font color:color];
    
    NSMutableAttributedString *hightlightString = [self attStringWithString:string font:font color:color];
    [hightlightString addAttribute:MALinkAttributeName value:userInfo range:NSMakeRange(0, hightlightString.length)];
    
    return hightlightString;
}
/**
 *  制作普通富文本
 */
+ (NSMutableAttributedString *)attStringWithString:(NSString *)string font:(UIFont *)font color:(UIColor *)color{
    if (!string) string = @"";
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    if (font)
        [attributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedString.length)];
    if (color)
        [attributedString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

#pragma mark - 正则表达式
static NSRegularExpression *regexAtagFormat;
static NSRegularExpression *regexHttp;
//static NSRegularExpression *regexBracket;
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
        // {{}}
//        regexBracket = [NSRegularExpression regularExpressionWithPattern:@"\\{\\{(.+?)\\}\\}" options:kNilOptions error:NULL];
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

#pragma mark userInfo制作
+ (NSMutableDictionary *)userInfoWithType:(kMALinkType)linkType title:(NSString *)title key:(NSString *)key{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:@(linkType) forKey:MALinkType];
    [userInfo setObject:title?:@"" forKey:MALinkTitle];
    [userInfo setObject:key?:@"" forKey:MALinkKey];
    return userInfo;
}

+ (id)attribute:(NSAttributedString *)attribute attributeName:(NSString *)attributeName atIndex:(NSUInteger)index {
    if (!attributeName) return nil;
    if (index > attribute.length || attribute.length == 0) return nil;
    if (attribute.length > 0 && index == attribute.length) index--;
    return [attribute attribute:attributeName atIndex:index effectiveRange:NULL];
}

@end
