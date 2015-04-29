//
//  ViewController.swift
//  ProductPurchaseAppSwift
//
//  Created by Admin on 4/29/15.
//  Copyright (c) 2015 IphoneGameZone. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource, UITableViewDelegate
{
    @IBOutlet weak var m_productTableView: UITableView!
    
    @IBOutlet weak var m_statusLabel: UILabel!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(animated: Bool)
    {
        m_productTableView.reloadData()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int)->Int
    {
        return 10
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cel: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cellID")
        
        cel.textLabel.text = "Row #\(indexPath.row)"
        cel.detailTextLabel?.text = "Subtitle #\(indexPath.row)"
        
        return cel;
    }

    @IBAction func restorePressed(sender: UIBarButtonItem)
    {
        println("restorePressed!")
    }

}

