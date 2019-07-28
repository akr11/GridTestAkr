//
//  CollectionViewCell.swift
//  GridTestAkr
//
//  Created by Andriy Kruglyanko on 7/27/19.
//  Copyright © 2019 andriyKruglyanko. All rights reserved.
//

import UIKit

protocol DeleteOneImageDelegate {
    func deleteOneImageClicked(tag: Int, idEnt: String)
}

class CollectionViewCell: UICollectionViewCell {
     @IBOutlet weak var curImageView: UIImageView!
    @IBOutlet weak var deleteOneImageButton: UIButton!
    var delegateDeleteOneImage: DeleteOneImageDelegate!
    var idEnt: String!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBAction func clickedDeleteOneImage(_ sender: Any) {
        if self.delegateDeleteOneImage != nil {
            delegateDeleteOneImage.deleteOneImageClicked(tag: self.tag, idEnt: self.idEnt)
        }
        
    }
    
}
