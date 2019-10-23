//
//  MAViewController.m
//  MALabel
//
//  Created by ma772528138@qq.com on 08/12/2019.
//  Copyright (c) 2019 ma772528138@qq.com. All rights reserved.
//

#import "MAViewController.h"
#import "MAAutoLayout.h"
#import "MALabel.h"

@interface MAViewController ()

@end

@implementation MAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MALabel *label = [[MALabel alloc] init];
    label.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:label];
    [label ma_makeConstraints:^(MAAutoLayout * _Nonnull make) {
        make.top.equalTo(self.view).offset(100);
        make.left.equalTo(self.view).offset(30);
        make.right.equalTo(self.view).offset(-30);
    }];
    label.linkTapBlock = ^(MALabel *la, id value) {
        NSLog(@"TapLink:%@",value);
    };
    label.linkLongPressBlock = ^(MALabel *la, id value) {
        NSLog(@"LongPressLinkL:%@",value);
    };
    NSMutableAttributedString *attStr = [MAContentLabelHelp attributedString:@"您将同意《 巴拉巴拉小魔仙协议 》werwerwekmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfgkmdflkjglkfjslkdjfglkjdsflkglkdsfjglkfjlfdjglkjdlk 18743849283 ma772528138@qq.com www.baidu.com http://www.kf5.com w.c.c " labelHelpHandle:MALabelHelpHandleAll font:nil color:nil];
    [attStr addAttribute:MALinkAttributeName value:@{@"name":@"babalalaxiaomixian",@"url":@"https://www.baidu.com"}range:NSMakeRange(6, 9)];
    [attStr addAttribute:MALinkTextTouchAttributesName value:@{NSBackgroundColorAttributeName : UIColor.redColor} range:NSMakeRange(6, 9)];
    [attStr addAttributes:@{NSForegroundColorAttributeName: [UIColor redColor]} range:NSMakeRange(6, 9)];
    [attStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleThick] range:NSMakeRange(0, 6)];
    NSString *str3 = @"dfsdfdsfdfly";
    NSDictionary *dictAttr3 = @{NSFontAttributeName:[UIFont fontWithName:@"futura" size:14],NSLigatureAttributeName:[NSNumber numberWithInteger:1]};
    NSAttributedString *attr3 = [[NSAttributedString alloc]initWithString:str3 attributes:dictAttr3];
    [attStr appendAttributedString:attr3];
    
    //    label.linkTextAttributes =  @{NSForegroundColorAttributeName : [UIColor greenColor],NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleThick]};
    
    //声明表情资源 NSTextAttachment类型
    NSAttributedString *imageString = [MAContentLabelHelp attStringWithImage:[UIImage imageNamed:@"123.jpg"] font:[UIFont systemFontOfSize:30] spacing:5 userInfo:@{}];
    [attStr insertAttributedString:imageString atIndex:0];
    
    [attStr addAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:30]} range:NSMakeRange(0, attStr.length)];
    
    [attStr addAttribute:MALinkTextTouchAttributesName value:@{NSForegroundColorAttributeName: [UIColor greenColor]} range:NSMakeRange(0, attStr.length)];

    label.attributedText = attStr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}

@end
