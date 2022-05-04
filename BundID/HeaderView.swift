//
//  HeaderView.swift
//  BundID
//
//  Created by Andreas Ganske on 04.05.22.
//

import SwiftUI

struct HeaderView: View {
    
    var title: String
    var text: String?
    var imageName: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 24) {
                Text(title)
                    .font(.bundLargeTitle)
                if let text = text {
                    Text(text)
                        .font(.bundBody)
                }
            }
            .padding(.horizontal)
            if let imageName = imageName {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(title: "Haben Sie noch Ihren PIN-Brief?",
                   text: "Der PIN-Brief wurde Ihnen nach der Beantragung des Ausweises zugesandt.",
                   imageName: "PIN-Brief")
        .previewLayout(.sizeThatFits)
    }
}
