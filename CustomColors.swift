import SwiftUI

extension Color {
    // Light mode: Light gray backgrounds, white fields/items
    // Dark mode: Black backgrounds, gray fields/items
    
    static let appBackground: Color = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.systemGray6
    })
    
    static let appItemBackground: Color = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray6 : UIColor.white
    })
    
    static let appFieldBackground: Color = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray6 : UIColor.white
    })
    
    static let appSearchBackground: Color = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? UIColor.systemGray5 : UIColor.white
    })
}

