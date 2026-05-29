import SwiftUI
import WidgetKit

@main
struct IllUsionWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            VPNLiveActivity()
        }
    }
}
