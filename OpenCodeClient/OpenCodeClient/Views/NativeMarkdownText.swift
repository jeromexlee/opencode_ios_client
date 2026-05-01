import Foundation
import SwiftUI

struct NativeMarkdownText: View {
    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        renderedText
    }

    private var renderedText: Text {
        guard let attributed = try? AttributedString(markdown: text) else {
            return Text(text)
        }
        return Text(attributed)
    }
}
