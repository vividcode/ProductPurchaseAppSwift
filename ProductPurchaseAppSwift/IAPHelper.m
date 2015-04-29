//
//  IAPHelper.m
//  ProductPurchaseApp
//
//  Created by Nirav Bhatt on 1/30/15.
//  Copyright (c) 2015 IphoneGameZone. All rights reserved.
//

#import "IAPHelper.h"

static NSString * productIDArray[5] =
{
    IAP_PRODUCT_C1, IAP_PRODUCT_C2, IAP_PRODUCT_NC1, IAP_PRODUCT_NC2, IAP_PRODUCT_NC3
};

@implementation IAPHelper

@synthesize m_productStoreArray, m_productsRequest, m_selectedProductTitles, m_selectedProductIDs, m_errorDescription, m_bStoreIsReachable;

#pragma mark -
#pragma mark SingleTon Creation
+ (instancetype) sharedInstance
{
    static IAPHelper * instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken,
    ^{
        instance = [[IAPHelper alloc] init];
        [self setupReachability:instance];
    });
    
    return instance;
}

+ (void) setupReachability : (IAPHelper *) instance
{
    Reachability* reach = [Reachability reachabilityWithHostname:@"itunes.apple.com"];

    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(),
       ^{
           instance.m_bStoreIsReachable = YES;
           instance.m_bReachabilityTested = YES;
           [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerReachabilityChangedNotification object:nil userInfo:nil];
       });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(),
       ^{
           instance.m_bStoreIsReachable = NO;
           instance.m_bReachabilityTested = YES;           
           [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerReachabilityChangedNotification object:nil userInfo:nil];
       });
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

#pragma mark -
#pragma mark Publics
//Start loading the store - will notify if user is offline. Will load the store if online.
- (void)loadStore
{
    [self initProductRequest];
}

- (BOOL) purchaseProduct : (NSString *) productID
{
    BOOL bCanLoadStore = [self canMakePurchases];
    //Reset properties accessed by UI
    if (bCanLoadStore)
    {
        [self updateSelectedProductIDsAndTitles: nil :nil];
        [self addPaymentForProductID:productID];
    }
    
    return bCanLoadStore;
}

//TODO: You may or may not need to replace this with your implementation.
//If you used NSUserDefaults inside provideContent AS IS, no change is required here.
//If you changed provideContent, change this accordingly.
- (NSUInteger) getPurchasedProduct : (NSString *) productID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString * value = [defaults valueForKey:productID];
    
    if (value)
    {
        NSUInteger quantity = [value integerValue];
        return quantity;
    }
    
    return -1;
}
//TODO: End

//This is restore command initiated by user action
- (void) restoreProducts
{
    //Reset properties accessed by UI
    [self updateSelectedProductIDsAndTitles: nil :nil];
    [self restoreTransactions];
}

//this will enable this instance to start monitoring status updates from storekit.
//should be ideally called after app launch.
- (void) addTransactionObserver
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void) removeTransactionObserver
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}


#pragma mark -
#pragma mark 1 - Requesting Product
- (void) initProductRequest
{
    NSSet * productIDSet = [[NSSet alloc] initWithObjects:productIDArray count:sizeof(productIDArray)/sizeof(productIDArray[0])];
    
    m_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIDSet];
    m_productsRequest.delegate = self;
    
    [m_productsRequest start];
}

#pragma mark -
#pragma mark 1A - Requesting Product Delegates
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (m_productStoreArray)
    {
        [m_productStoreArray removeAllObjects];
        m_productStoreArray = nil;
    }
    
    for (NSString *invalidProductId in response.invalidProductIdentifiers)
    {
        NSString * msg = [NSString stringWithFormat:@"Purchase not found: %@",invalidProductId];
        NSLog(@"%@", msg);
        return;
    }

    m_productStoreArray = [response.products mutableCopy];
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchedNotification object:nil userInfo:nil];
}

//Successful request completion. Needed to release m_productsRequest.
-(void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"%@", request);
    m_productsRequest = nil;
}

//Product Request failed, and this is needed to release m_productsRequest, and to notify UI about failure in fetch.
-(void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (error)
    {
        NSLog(@"Failed to fetch products: %@", [error localizedDescription]);
        m_errorDescription = [error localizedDescription];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerProductsFetchFailedNotification object:nil userInfo:nil];
    m_productsRequest = nil;
}

#pragma mark -
#pragma mark 2 - Adding Payment to Payment Queue
- (BOOL)canMakePurchases
{
    return [SKPaymentQueue canMakePayments];
}

- (void) addPaymentForProductID: (NSString *) productID
{
    for (SKProduct * product in self.m_productStoreArray)
    {
        if ([product.productIdentifier isEqualToString:productID])
        {
            SKMutablePayment * payment = [SKMutablePayment paymentWithProduct:product];
            [[SKPaymentQueue defaultQueue] addPayment:payment];
            break;
        }
    }
}

#pragma mark -
#pragma mark 2A - Adding Payment to Payment Queue - No Delegates

#pragma mark -
#pragma mark 3 - Monitor Transaction Queue - No Methods


#pragma mark -
#pragma mark 3A - Monitor Transaction Queue Delegates
// called when the transaction status is updated
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStatePurchased:
                if (transaction.originalTransaction)
                {
                    //duplicate purchase = restore flow
                    [self handleTransactionCompletion:transaction :YES];
                }
                else
                {
                    //purchase flow
                    [self handleTransactionCompletion:transaction :NO];
                }
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                NSLog(@"failed");
                break;
            case SKPaymentTransactionStateRestored:
                [self handleTransactionCompletion:transaction :YES];
                NSLog(@"Restored");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Deferred");
                break;
            default:
                break;
        }
    }
}

#pragma mark -
#pragma mark 4 - Restore
//Call Storekit method to restore non-consumables.
- (void) restoreTransactions
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark -
#pragma mark 4A - Restore Delegates
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    if (queue.transactions.count > 0)
    {
        for (SKPaymentTransaction * transaction in queue.transactions)
        {
            NSLog(@"RestoreCompleted %@", transaction.payment.productIdentifier);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionRestoredNotification object:nil userInfo:nil];
    }
}

//This is a delegate method called by Storekit to indicate restore has failed.
- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    switch (error.code)
    {
        case SKErrorPaymentCancelled:
        case SKErrorUnknown:
        case SKErrorClientInvalid:
        case SKErrorPaymentInvalid:
        case SKErrorPaymentNotAllowed:
        default:
            break;
    }
    NSLog(@"%@", [error localizedDescription]);
    
    m_errorDescription = [error.localizedDescription copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionRestoreFailedNotification object:nil userInfo:nil];
}

#pragma mark -
#pragma mark Transaction Completion Helpers
- (void) unlockAndFinish : (SKPaymentTransaction *)transaction :(BOOL)bRestore
{
    if (bRestore)
    {
        [self provideContent:transaction.originalTransaction];
    }
    else
    {
        [self provideContent:transaction];
    }
    
    //finish must happen with THIS TRANSACTION,
    //no matter if it's restore or purchase.
    [self finishTransaction:transaction bSuccessful:YES];
}

//TODO: You may or may not need to replace this with your implementation.
//Use NSUserDefaults (as done here), Use Keychain, start downloading
//content from Apple Servers, or one of your own.
//Remember: It's your product, it's your money (well, 70% of it MINUS taxes!!!)
//So write this function wisely!
- (void) provideContent : (SKPaymentTransaction *)transaction
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@(transaction.payment.quantity) forKey:transaction.payment.productIdentifier];
    [defaults synchronize];
}
//TODO: End

- (void)finishTransaction:(SKPaymentTransaction *)transaction bSuccessful:(BOOL)bSuccessful
{
    // remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    if (bSuccessful)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kInAppPurchaseManagerTransactionFailedNotification object:nil];
    }
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    for (SKProduct * product in m_productStoreArray)
    {
        if ([product.productIdentifier isEqualToString:transaction.payment.productIdentifier])
        {
            [self updateSelectedProductIDsAndTitles: product.productIdentifier :product.localizedTitle];
            break;
        }
    }
    
    if (transaction.error)
    {
        m_errorDescription = [transaction.error localizedDescription];
    }
    
    [self finishTransaction:transaction bSuccessful:NO];
}

- (void) handleTransactionCompletion:(SKPaymentTransaction *)transaction :(BOOL)bRestore
{
    for (SKProduct * product in m_productStoreArray)
    {
        if ([product.productIdentifier isEqualToString:transaction.payment.productIdentifier])
        {
            [self updateSelectedProductIDsAndTitles: product.productIdentifier :product.localizedTitle];
            break;
        }
    }
  
  //  Upcoming: Receipt Validation
  //  [self verifyReceipt:transaction :bRestore];
  [self unlockAndFinish:transaction :bRestore];
}

#pragma mark -
#pragma mark Miscellaneous Helpers
- (NSString *) getLocalizedCurrencyString : (NSNumber *) amount :(NSLocale *)priceLocale
{
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setLocale:priceLocale];
    [currencyFormatter setMaximumFractionDigits:2];
    [currencyFormatter setMinimumFractionDigits:2];
    [currencyFormatter setAlwaysShowsDecimalSeparator:YES];
    [currencyFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    NSString *localizedCurrency = [currencyFormatter stringFromNumber:amount];
    return localizedCurrency;
}

- (void) updateSelectedProductIDsAndTitles : (NSString *) productID :(NSString *) productTitle
{
    if (!productID || [productID isEqualToString:@""] || !productTitle || [productTitle isEqualToString:@""])
    {
        m_selectedProductIDs = nil;
        m_selectedProductTitles = nil;
        return;
    }
    
    if (m_selectedProductIDs && ![m_selectedProductIDs isEqualToString:@""])
    {
        [m_selectedProductIDs appendString:@","];
        [m_selectedProductIDs appendString:productID];
    }
    else
    {
        m_selectedProductIDs = [productID mutableCopy];
    }
    
    if (m_selectedProductTitles && ![m_selectedProductTitles isEqualToString:@""])
    {
        [m_selectedProductTitles appendString:@","];
        [m_selectedProductTitles appendString:productTitle];
    }
    else
    {
        m_selectedProductTitles = [productTitle mutableCopy];
    }
}

@end
