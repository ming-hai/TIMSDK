
//  Created by Tencent on 2023/06/09.
//  Copyright © 2023 Tencent. All rights reserved.
/**
 *  This file declares the view model for the friend request interface.
 *  The view model can pull the friend application information through the interface provided by the IM SDK, and load the pulled information to facilitate the
 * further display of the friend application interface.
 */

#import <Foundation/Foundation.h>
#import "TUICommonPendencyCell_Minimalist.h"

NS_ASSUME_NONNULL_BEGIN

@interface TUINewFriendViewDataProvider_Minimalist : NSObject

@property(readonly) NSArray *dataList;

/**
 *  Has data not shown.
 *  YES：There are unshown requests；NO：All requests are loaded.
 */
@property BOOL hasNextData;

@property BOOL isLoading;

- (void)loadData;

- (void)removeData:(TUICommonPendencyCellData_Minimalist *)data;
- (void)agreeData:(TUICommonPendencyCellData_Minimalist *)data;
- (void)rejectData:(TUICommonPendencyCellData_Minimalist *)data;
@end

NS_ASSUME_NONNULL_END
