import SwiftUI
import RichText

struct HTMLView: View {
    
    let title: String
    let html: String
    
    var body: some View {
        ScrollView {
            htmlView
        }
        .navigationTitle(Text(verbatim: title))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder var htmlView: some View {
        RichText(html: html)
    }
}
