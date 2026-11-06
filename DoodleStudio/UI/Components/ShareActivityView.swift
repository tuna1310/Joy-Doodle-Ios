import SwiftUI
import UIKit

public struct ShareSheet: UIViewControllerRepresentable {
    public var items: [Any]
    public var applicationActivities: [UIActivity]?
    
    public init(items: [Any], applicationActivities: [UIActivity]? = nil) {
        self.items = items
        self.applicationActivities = applicationActivities
    }
    
    public init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.items = activityItems
        self.applicationActivities = applicationActivities
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

public typealias ShareActivityView = ShareSheet
