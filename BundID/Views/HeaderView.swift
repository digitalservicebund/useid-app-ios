//
//  HeaderView.swift
//  BundID
//
//  Created by Andreas Ganske on 04.05.22.
//

import SwiftUI

struct ImageMeta {
    let name: String
    let labelKey: String
}

struct HeaderView: View {
    
    var titleKey: String
    var bodyKey: String?
    var imageMeta: ImageMeta?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 24) {
                Text(localized: titleKey)
                    .font(.bundLargeTitle)
                    .foregroundColor(.blackish)
                if let body = bodyKey {
                    Text(localized: body)
                        .font(.bundBody)
                        .foregroundColor(.blackish)
                }
            }
            .padding(.horizontal)
            if let imageMeta = imageMeta {
                Image(decorative: imageMeta.name)
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
        HeaderView(titleKey: "firstTimeUser_intro_title",
                   bodyKey: "firstTimeUser_intro_body",
                   imageMeta: ImageMeta(name: "PIN-Brief", labelKey: "Alt Text"))
        .previewLayout(.sizeThatFits)
    }
}
