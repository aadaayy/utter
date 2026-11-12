import SwiftUI

/// Utter's look: plain and Apple-like, with one blue.
enum Theme {
    static let blue = Color(red: 0.18, green: 0.42, blue: 1.0)
    static let live = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let green = Color(red: 0.2, green: 0.72, blue: 0.4)
}

/// A rounded card on the grouped background.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
