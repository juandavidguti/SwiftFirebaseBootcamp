//
//  Utilities.swift
//  SwiftFirebaseBootcamp
//
//  Created by Juan David Gutierrez Olarte on 20/09/25.
//

import Foundation
import UIKit

final class Utilities: Sendable {
    
    static let shared = Utilities()
    private init() {}
    
    @MainActor
    func topViewController(controller: UIViewController? = nil) -> UIViewController? {
        // Resolve a starting controller using scene-based key window (iOS 13+)
        let startingController: UIViewController? = {
            if let controller = controller { return controller }
            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .windows
                .first { $0.isKeyWindow }
            return keyWindow?.rootViewController
        }()

        guard let controller = startingController else { return nil }

        if let nav = controller as? UINavigationController {
            return topViewController(controller: nav.visibleViewController)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(controller: selected)
        }
        if let presented = controller.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
    
}
