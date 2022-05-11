//
//  HeaderView.swift
//  BundID
//
//  Created by Andreas Ganske on 04.05.22.
//

import SwiftUI

struct ImageMeta {
    let name: String
    let labelKey: String? = nil
}

struct HeaderView: View {
    
    var titleKey: String
    var bodyKey: String?
    var imageMeta: ImageMeta?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 24) {
                Text(titleKey)
                    .font(.bundLargeTitle)
                    .foregroundColor(.blackish)
                if let body = bodyKey {
                    Text(body)
                        .font(.bundBody)
                        .foregroundColor(.blackish)
                }
            }
            .padding(.horizontal)
            if let imageMeta = imageMeta {
                imageMeta.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }
}

extension ImageMeta {
    var image: Image {
        if let labelKey = labelKey {
            return Image(name, label: Text(labelKey))
        } else {
            return Image(decorative: name)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(titleKey: L10n.FirstTimeUser.Intro.title,
                   bodyKey: L10n.FirstTimeUser.Intro.body,
                   imageMeta: ImageMeta(name: "PIN-Brief"))
        .previewLayout(.sizeThatFits)
    }
}
