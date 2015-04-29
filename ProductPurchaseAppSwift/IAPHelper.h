//
//  IAPHelper.h
//  ProductPurchaseApp
//
//  Created by Nirav Bhatt on 1/30/15.
//  Copyright (c) 2015 IphoneGameZone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "RMStore/RMStore.h"
#import "RMStore/Optional/RMStoreAppReceiptVerificator.h"
#import "RMStore/Optional/RMAppReceipt.h"
#import "Reachability.h"

//TODO:Replace these constant values with your actual Product IDs set up in iTunesConnect Portal.
//Warning:Do NOT change constant names!
//If you add/remove/modify any of the entries, change productIDArray inside IAPHelper.m accordingly.
#define IAP_PRODUCT_NC1 @"com.IphoneGameZone.SWIFTNC1"
#define IAP_PRODUCT_C1 @"com.IphoneGameZone.SWIFTC1"
//TODO: End

#define kInAppPurchaseManagerTransactionSucceededNotification @"Transaction Succeeded Notification"
#define kInAppPurchaseManagerProductsFetchedNotification @"Products Fetched"
#define kInAppPurchaseManagerProductsFetchFailedNotification @"Product Fetch Failed"
#define kInAppPurchaseManagerProductsReqFinishedNotification @"Transaction Finished Notification"
#define kInAppPurchaseManagerTransactionFailedNotification @"Transaction Failed Notification"
#define kInAppPurchaseManagerTransactionRestoredNotification @"Transaction Restored Notification"
#define kInAppPurchaseManagerTransactionRestoreFailedNotification @"Restore Failed Notification"
#define kInAppPurchaseManagerReachabilityChangedNotification @"Reachability Changed Notification"

#define PRODUCT_ARRAY_KEY_ID @"productID"
#define PRODUCT_ARRAY_KEY_TITLE @"productTitle"
#define PRODUCT_ARRAY_KEY_DESCRIPTION @"productDescription"
#define PRODUCT_ARRAY_KEY_PRICE @"productPrice"
#define PRODUCT_ARRAY_KEY_LOCALE @"productPriceLocale"

@interface IAPHelper : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    
}

+ (instancetype) sharedInstance;

- (void) loadStore;
- (NSUInteger) getPurchasedProduct : (NSString *) productID;
- (BOOL) purchaseProduct : (NSString *) productID;
- (void) addTransactionObserver;
- (void) removeTransactionObserver;
- (void) restoreProducts;


- (NSString *) getLocalizedCurrencyString : (NSNumber *) amount :(NSLocale *)priceLocale;

@property (nonatomic) NSString * m_errorDescription;
@property (nonatomic) SKProductsRequest *m_productsRequest;
@property (nonatomic) NSMutableString * m_selectedProductTitles;
@property (nonatomic) NSMutableString * m_selectedProductIDs;
@property (nonatomic) NSMutableArray * m_productStoreArray;
@property (nonatomic) BOOL m_bStoreIsReachable;
@property (nonatomic) BOOL m_bReachabilityTested;
@end
