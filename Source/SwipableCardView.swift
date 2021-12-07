//
//  SwipableCardView.swift
//  SwipableCardStack
//
//  Created by 윤재욱 on 2021/12/08.
//

import UIKit

class SwipableCardView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addShadow()
        backgroundColor = .blue
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addShadow() {
        
    }
}
