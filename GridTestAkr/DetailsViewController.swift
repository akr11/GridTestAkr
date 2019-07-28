//
//  DetailsViewController.swift
//  GridTestAkr
//
//  Created by Andriy Kruglyanko on 7/27/19.
//  Copyright © 2019 andriyKruglyanko. All rights reserved.
//

import UIKit
import Kingfisher

class DetailsViewController: UIViewController {
    
    var selectedPhoto: Photo!
    @IBOutlet weak var curImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let _ = selectedPhoto.url as? String
            else {
                return
        }
        var s =  String(format: selectedPhoto.url ?? "-")
        print(s)
        let url = URL(string:s)!
        curImageView.kf.indicatorType = IndicatorType.activity
        curImageView.kf.setImage(with: url)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        curImageView.kf.cancelDownloadTask()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
