//
//  UIViewController+Layout.swift
//  AccessToInsight
//
//  Created by Bill Parousis on 2019-11-24.
//

import Foundation
import UIKit

extension UIViewController {
    func anchor(to subView: UIView) {
        if #available(iOS 11, *) {
            let guide = view.safeAreaLayoutGuide
            NSLayoutConstraint.activate([
                subView.topAnchor.constraint(equalTo: guide.topAnchor),
                subView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
                subView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
                subView.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
                ])
        } else {
            let margins = view.layoutMarginsGuide
            NSLayoutConstraint.activate([
                subView.topAnchor.constraint(equalTo: margins.topAnchor),
                subView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
                subView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
                subView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
                ])
        }
    }
}
