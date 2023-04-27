//
//  TUITranslationExtensionObserver.m
//  TUITranslation
//
//  Created by xia on 2023/4/4.
//

#import "TUITranslationExtensionObserver.h"

#import <TUICore/TUICore.h>
#import <TUICore/TUIDefine.h>
#import <TIMCommon/TIMPopActionProtocol.h>
#import <TIMCommon/TUIMessageCell.h>
#import <TUIChat/TUITextMessageCell.h>
#import <TUIChat/TUIReferenceMessageCell.h>
#import <TUIChat/TUIReplyMessageCell.h>
#import <TUIChat/TUITextMessageCell_Minimalist.h>
#import <TUIChat/TUIReferenceMessageCell_Minimalist.h>
#import <TUIChat/TUIReplyMessageCell_Minimalist.h>
#import "TUITranslationConfig.h"
#import "TUITranslationLanguageController.h"
#import "TUITranslationView.h"
#import "TUITranslationDataProvider.h"

@interface TUITranslationExtensionObserver () <TUIExtensionProtocol>

@property (nonatomic, weak) UINavigationController *navVC;
@property (nonatomic, weak) TUICommonTextCellData *cellData;

@end

@implementation TUITranslationExtensionObserver

static id _instance = nil;

+ (void)load {
    TUIRegisterThemeResourcePath(TUITranslationThemePath, TUIThemeModuleTranslation);
    
    // UI extensions in pop menu when message is long pressed.
    [TUICore registerExtension:TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID object:TUITranslationExtensionObserver.shareInstance];
    [TUICore registerExtension:TUICore_TUIChatExtension_PopMenuActionItem_MinimalistExtensionID object:TUITranslationExtensionObserver.shareInstance];
    
    // UI extensions of setting.
    [TUICore registerExtension:TUICore_TUIContactExtension_MeSettingMenu_ClassicExtensionID object:TUITranslationExtensionObserver.shareInstance];
    [TUICore registerExtension:TUICore_TUIContactExtension_MeSettingMenu_MinimalistExtensionID object:TUITranslationExtensionObserver.shareInstance];
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [TUICore registerExtension:TUICore_TUIChatExtension_BottomContainer_ClassicExtensionID object:self];
        [TUICore registerExtension:TUICore_TUIChatExtension_BottomContainer_MinimalistExtensionID object:self];
    }
    return self;
}

#pragma mark - TUIExtensionProtocol
- (void)onRaiseExtension:(NSString *)extensionID parentView:(UIView *)parentView param:(nullable NSDictionary *)param {
    if ([extensionID isEqualToString:TUICore_TUIChatExtension_BottomContainer_ClassicExtensionID] ||
        [extensionID isEqualToString:TUICore_TUIChatExtension_BottomContainer_MinimalistExtensionID]) {
        NSObject *data = [param objectForKey:TUICore_TUIChatExtension_BottomContainer_CellData];
        if (![parentView isKindOfClass:UIView.class] || ![data isKindOfClass:TUIMessageCellData.class]) {
            return;
        }
        
        TUIMessageCellData *cellData = (TUIMessageCellData *)data;
        if (cellData.innerMessage.elemType != V2TIM_ELEM_TYPE_TEXT) {
            return;
        }
        
        TUITranslationView *view = [[TUITranslationView alloc] initWithData:cellData];
        [parentView addSubview:view];
    }
}

- (NSArray<TUIExtensionInfo *> *)onGetExtension:(NSString *)extensionID param:(NSDictionary *)param {
    if (![extensionID isKindOfClass:NSString.class]) {
        return nil;
    }
    
    if ([extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID] ||
        [extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_MinimalistExtensionID]) {
        // Extension entrance in pop menu when message is long pressed.
        if (![param isKindOfClass:NSDictionary.class]) {
            return nil;
        }
        TUIMessageCell *cell = param[TUICore_TUIChatExtension_PopMenuActionItem_ClickCell];
        if ([extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID]) {
            if (![cell isKindOfClass:TUITextMessageCell.class] &&
                ![cell isKindOfClass:TUIReferenceMessageCell.class] &&
                ![cell isKindOfClass:TUIReplyMessageCell.class]) {
                return nil;
            }
        } else if ([extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_MinimalistExtensionID]) {
            if (![cell isKindOfClass:TUITextMessageCell_Minimalist.class] &&
                ![cell isKindOfClass:TUIReferenceMessageCell_Minimalist.class] &&
                ![cell isKindOfClass:TUIReplyMessageCell_Minimalist.class]) {
                return nil;
            }
        }
        if (cell.messageData.innerMessage.elemType != V2TIM_ELEM_TYPE_TEXT) {
            return nil;
        }
        if ([TUITranslationDataProvider shouldShowTranslation:cell.messageData.innerMessage]) {
            return nil;
        }
        if (![self isSelectAllContentOfMessage:cell]) {
            return nil;
        }
        
        TUIExtensionInfo *info = [[TUIExtensionInfo alloc] init];
        info.weight = 2000;
        info.text = TIMCommonLocalizableString(TUIKitTranslate);
        if ([extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_ClassicExtensionID]) {
            info.icon = TUIChatBundleThemeImage(@"chat_icon_translate_img", @"icon_translate");
        } else if ([extensionID isEqualToString:TUICore_TUIChatExtension_PopMenuActionItem_MinimalistExtensionID]) {
            info.icon = [UIImage imageNamed:TUIChatImagePath_Minimalist(@"icon_translate")];
        }
        info.onClicked = ^(NSDictionary * _Nonnull action) {
            TUIMessageCellData *cellData = cell.messageData;
            V2TIMMessage *message = cellData.innerMessage;
            if (message.elemType != V2TIM_ELEM_TYPE_TEXT) {
                return;
            }
            [TUITranslationDataProvider translateMessage:cellData
                                              completion:^(NSInteger code, NSString * _Nonnull desc, TUIMessageCellData * _Nonnull data, NSInteger status, NSString * _Nonnull text) {
                NSDictionary *param = @{TUICore_TUITranslationNotify_DidChangeTranslationSubKey_Data: cellData};
                [TUICore notifyEvent:TUICore_TUITranslationNotify
                              subKey:TUICore_TUITranslationNotify_DidChangeTranslationSubKey
                              object:nil
                               param:param];
            }];
        };
        return @[info];
    } else if ([extensionID isEqualToString:TUICore_TUIContactExtension_MeSettingMenu_ClassicExtensionID] ||
               [extensionID isEqualToString:TUICore_TUIContactExtension_MeSettingMenu_MinimalistExtensionID]) {
        // Extension entrance in Me setting VC.
        if (![param isKindOfClass:NSDictionary.class]) {
            return nil;
        }
        if (param[TUICore_TUIContactExtension_MeSettingMenu_Nav]) {
            self.navVC = param[TUICore_TUIContactExtension_MeSettingMenu_Nav];
        }

        TUICommonTextCellData *data = [TUICommonTextCellData new];
        data.key = TIMCommonLocalizableString(TranslateMessage);
        data.showAccessory = YES;
        data.value = [TUITranslationConfig defaultConfig].targetLanguageName;
        self.cellData = data;

        TUICommonTextCell *cell = [[TUICommonTextCell alloc] init];
        [cell fillWithData:data];
        cell.mm_height(60).mm_width(Screen_Width);
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickedTargetLanguageCell:)];
        [cell addGestureRecognizer:tap];

        TUIExtensionInfo *info = [[TUIExtensionInfo alloc] init];
        NSMutableDictionary *param = [NSMutableDictionary dictionary];
        [param setObject:@450 forKey:TUICore_TUIContactExtension_MeSettingMenu_Weight];
        if (cell) {
            [param setObject:cell forKey:TUICore_TUIContactExtension_MeSettingMenu_View];
        }
        if (data) {
            [param setObject:data forKey:TUICore_TUIContactExtension_MeSettingMenu_Data];
        }
        info.data = param;
        return @[info];
    }
    return nil;
}

- (void)onClickedTargetLanguageCell:(TUICommonTextCell *)cell {
    TUITranslationLanguageController *vc = [[TUITranslationLanguageController alloc] init];
    vc.onSelectedLanguage = ^(NSString * _Nonnull languageName) {
        self.cellData.value = languageName;
    };
    if (self.navVC) {
        [self.navVC pushViewController:vc animated:YES];
    }
}

- (BOOL)isSelectAllContentOfMessage:(TUIMessageCell *)cell {
    if ([cell isKindOfClass:TUITextMessageCell.class]) {
        TUITextMessageCell *textCell = (TUITextMessageCell *)cell;
        if (textCell.selectContent.length == 0) {
            return YES;
        } else {
            NSAttributedString *selectedString = [textCell.textView.attributedText attributedSubstringFromRange:textCell.textView.selectedRange];
            if (selectedString.length == 0) {
                return YES;
            }
            return selectedString.length == textCell.textView.attributedText.length;
        }
    } else if ([cell isKindOfClass:TUIReferenceMessageCell.class]) {
        TUIReferenceMessageCell *refCell = (TUIReferenceMessageCell *)cell;
        if (refCell.selectContent.length == 0) {
            return YES;
        } else {
            NSAttributedString *selectedString = [refCell.textView.attributedText attributedSubstringFromRange:refCell.textView.selectedRange];
            if (selectedString.length == 0) {
                return YES;
            }
            return selectedString.length == refCell.textView.attributedText.length;
        }
    } else if ([cell isKindOfClass:TUIReplyMessageCell.class]) {
        TUIReplyMessageCell *replyCell = (TUIReplyMessageCell *)cell;
        if (replyCell.selectContent.length == 0) {
            return YES;
        } else {
            NSAttributedString *selectedString = [replyCell.textView.attributedText attributedSubstringFromRange:replyCell.textView.selectedRange];
            if (selectedString.length == 0) {
                return YES;
            }
            return selectedString.length == replyCell.textView.attributedText.length;
        }
    }
    if ([cell isKindOfClass:TUITextMessageCell_Minimalist.class] ||
        [cell isKindOfClass:TUIReferenceMessageCell_Minimalist.class] ||
        [cell isKindOfClass:TUIReplyMessageCell_Minimalist.class]) {
        return YES;
    }
    return NO;
}

@end

