//
//  ViewController.swift
//  ProductPurchaseAppSwift
//
//  Created by Admin on 4/29/15.
//  Copyright (c) 2015 IphoneGameZone. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate
{
    @IBOutlet weak var m_productTableView: UITableView!
    
    @IBOutlet weak var m_statusLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.registerObserver()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(animated: Bool)
    {
        self.loadProducts()
    }
    
    deinit
    {
        self.unRegisterObserver()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerObserver()
    {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "purchaseSucceeded",
            name: kInAppPurchaseManagerTransactionSucceededNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "purchaseFailed",
            name: kInAppPurchaseManagerTransactionFailedNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "productsFetched",
            name: kInAppPurchaseManagerProductsFetchedNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "productsFetchFailed",
            name: kInAppPurchaseManagerProductsFetchFailedNotification,
            object: nil)
    
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "restoreSucceeded",
            name: kInAppPurchaseManagerTransactionRestoredNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "restoreFailed",
            name: kInAppPurchaseManagerTransactionRestoreFailedNotification,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "storeReachabilityChanged",
            name: kInAppPurchaseManagerReachabilityChangedNotification,
            object: nil)
    }
    
    func unRegisterObserver()
    {
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerTransactionSucceededNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerTransactionFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerProductsFetchedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerProductsFetchFailedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerTransactionRestoredNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(
            self, name: kInAppPurchaseManagerTransactionRestoreFailedNotification, object: nil)
     
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)->Int
    {
        if var productArray = IAPHelper.sharedInstance().m_productStoreArray
        {
            let count: Int = productArray.count;
            return count;
        }
        else
        {
            return 0;
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let product: SKProduct = IAPHelper.sharedInstance().m_productStoreArray.objectAtIndex(indexPath.row) as SKProduct
        
        let title: NSString = product.localizedTitle as NSString
        
        let priceLocale: NSLocale = product.priceLocale as NSLocale
        
        let price: NSString = IAPHelper.sharedInstance().getLocalizedCurrencyString(product.price, priceLocale)
        
        
        let cel: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cellID")
        
        cel.textLabel.text = title
        cel.detailTextLabel?.text = price
        
        return cel;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var product: SKProduct? = IAPHelper.sharedInstance().m_productStoreArray.objectAtIndex(indexPath.row) as? SKProduct
        
        if (product != nil)
        {
            self.purchaseProduct(product!.productIdentifier)
        }
        else
        {
            self.displayStatusLabel("Please select a valid product first.", delay:5.0)
        }
    }
    
    func loadProducts()
    {
        var productArray = IAPHelper.sharedInstance().m_productStoreArray
        var productCount: Int = 0
        
        if (productArray != nil)
        {
            productCount = productArray.count
        }        
            
        if (productCount == 0)
        {
            if (IAPHelper.sharedInstance().m_bStoreIsReachable == true)
            {
                self.showProgressIndicator("Loading Products")
                IAPHelper.sharedInstance().loadStore();
            }
        else
            {
                if (IAPHelper.sharedInstance().m_bReachabilityTested == true)
                {
                    self.displayStatusLabel("Internet disconnected.", delay: 5)
                }
            }
        }
        else
        {
            m_productTableView.reloadData();
        }
    }
    
    func purchaseProduct (productIdentifier :String)
    {
        if (IAPHelper.sharedInstance().m_bStoreIsReachable)
        {
            var bCanLoadStore = IAPHelper.sharedInstance().purchaseProduct(productIdentifier)
            
            //see that purchase is already happening...
            if (bCanLoadStore == true)
            {
                self.showProgressIndicator("Purchasing...")
            }
            else
            {
                self.displayStatusLabel("Purchase not allowed.",delay:5.0)
            }
        }
        else
        {
            if (IAPHelper.sharedInstance().m_bReachabilityTested)
            {
                self.displayStatusLabel("Internet disconnected. Please try again.", delay:5.0)
            }
        }
    }
    
    @IBAction func restorePressed(sender: UIBarButtonItem)
    {
        if (IAPHelper.sharedInstance().m_bStoreIsReachable)
        {
            IAPHelper.sharedInstance().restoreProducts()
        }
        else
        {
            if (IAPHelper.sharedInstance().m_bReachabilityTested)
            {
                self.displayStatusLabel("Internet disconnected. Please try again.", delay:5)
            }
        }
    }

    
    func configureStatusLabel()
    {
        m_statusLabel.layer.cornerRadius = 8.0;
        m_statusLabel.layer.masksToBounds = true;
        
        let loginErrorGestureRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "errorTapped")
        
        loginErrorGestureRecognizer.numberOfTapsRequired = 1;
        loginErrorGestureRecognizer.delegate = self;
        
        self.m_statusLabel.addGestureRecognizer(loginErrorGestureRecognizer)
    }
    
    func displayStatusLabel (message :NSString,  delay :Double)
    {
        m_statusLabel.text = message;
        m_statusLabel.hidden = false;
        
        self.view.bringSubviewToFront(m_statusLabel);
        
        if (delay >= 0.0)
        {
            var dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, dispatch_get_main_queue(),
            {
                self.hideError()
            })
        }
    }
    
    func errorTapped (recognizer :UIGestureRecognizer)
    {
        self.hideError()
    }
    
    func hideError()
    {
        m_statusLabel.hidden = true;
    }
    
    func storeReachabilityChanged()
    {
        //try to load products every time reachability changes.
        //so that UI can respond to connectivity changes.
        self.loadProducts()
    }
  
    func purchaseSucceeded()
    {
        self.hideProgressIndicator()
        let message: NSString = "Congratulations!" + IAPHelper.sharedInstance().m_selectedProductTitles +  "unlocked successfully!"
        
        self.displayStatusLabel(message, delay: 5.0)
    }
    
    func purchaseFailed()
    {
        self.hideProgressIndicator()
        let message: NSString = "Purchase failed :" + IAPHelper.sharedInstance().m_errorDescription
        self.displayStatusLabel(message, delay: 5.0)
    }
    
    func productsFetched()
    {
        self.hideProgressIndicator()
        
        if (IAPHelper.sharedInstance().m_productStoreArray.count == 0)
        {
            self.displayStatusLabel("No Products Found.", delay: 5.0)
            return;
        }
        
        m_productTableView.reloadData()
    }
    
    func productsFetchFailed()
    {
        self.hideProgressIndicator()
        let message: NSString = "Could not load the Store: " + IAPHelper.sharedInstance().m_errorDescription
        self.displayStatusLabel(message, delay: 5.0)
    }
    
    func restoreSucceeded()
    {
        self.hideProgressIndicator()
        let message: NSString = IAPHelper.sharedInstance().m_selectedProductTitles + " restored successfully."
        self.displayStatusLabel (message, delay: 5.0)
    }
    
    func  restoreFailed()
    {
        self.hideProgressIndicator()
        let message: NSString = "Restore failed: " + IAPHelper.sharedInstance().m_errorDescription
        self.displayStatusLabel (message, delay: 5.0)
    }

    func showProgressIndicator (message :NSString)
    {
        SVProgressHUD.showWithStatus(message, maskType: SVProgressHUDMaskType.Gradient)
    }
    
    func hideProgressIndicator()
    {
        if (SVProgressHUD.isVisible())
        {
            SVProgressHUD.dismiss()
        }
    }
}

