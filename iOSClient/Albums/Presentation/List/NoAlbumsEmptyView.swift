// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Dhanesh
// SPDX-FileCopyrightText: 2026 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

//struct NoAlbumsEmptyView: View {
//    let onNewAlbumCreationIntent: () -> Void
//    @Environment(\.localAccount) var localAccount: String
//
//    var body: some View {
//        GeometryReader { geometry in
//            ScrollView(.vertical) {
//                VStack(spacing: 0) {
//                    Spacer(minLength: 0)
//
//                    Image(systemName: "photo.stack.fill")
//                        .resizable()
//                        .scaledToFit()
//                        .foregroundStyle(
//                            Color(NCBrandColor.shared.getElement(account: localAccount))
//                        )
//                        .frame(maxWidth: .infinity, maxHeight: 75)
//                        .padding(.bottom, 30)
//
//                    VStack(alignment: .center, spacing: 16) {
//                        Text(NSLocalizedString("_albums_list_empty_heading_", comment: ""))
//                            .cappedFont(.headline, maxDynamicType: .accessibility2)
//                            .multilineTextAlignment(.center)
//                            .frame(maxWidth: .infinity)
//
//                        Text(NSLocalizedString("_albums_list_empty_subheading_", comment: ""))
//                            .cappedFont(.subheadline, maxDynamicType: .accessibility1)
//                            .foregroundStyle(.secondary)
//                            .multilineTextAlignment(.center)
//                            .frame(maxWidth: .infinity)
//
//                        Button(action: onNewAlbumCreationIntent) {
//                            Label(
//                                NSLocalizedString(
//                                    "_albums_list_empty_new_album_btn_",
//                                    comment: ""
//                                ),
//                                systemImage: "plus"
//                            )
//                            .cappedFont(.subheadline, maxDynamicType: .accessibility1)
//                            .foregroundStyle(
//                                Color(NCBrandColor.shared.getElement(account: localAccount))
//                            )
//                        }
//                    }
//                    .padding(.horizontal, 32)
//
//                    Spacer(minLength: 0)
//                }
//                .frame(
//                    maxWidth: .infinity,
//                    minHeight: geometry.size.height
//                )
//            }
//        }
//    }
//}

struct NoAlbumsEmptyView: View {

    let onNewAlbumCreationIntent: () -> Void

    private let contentPadding: CGFloat = 32.0

    var body: some View {

        ScrollView(.vertical) {

            VStack {

                // Background image
                Image("noAlbum")
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 16) {

                    Text(NSLocalizedString("_albums_list_empty_heading_", comment: ""))
//                        .font(.system(size: 48, weight: .bold))
                        .cappedFont(.headline, maxDynamicType: .accessibility2)

                    Text(NSLocalizedString("_albums_list_empty_subheading_", comment: ""))
//                        .font(.system(size: 15, weight: .regular))
                        .cappedFont(.subheadline, maxDynamicType: .accessibility1)
                        .foregroundColor(.secondary)

                    Button(action: onNewAlbumCreationIntent) {
                        Label(NSLocalizedString("_albums_list_empty_new_album_btn_", comment: ""), systemImage: "plus")
//                            .font(.system(size: 15, weight: .medium))
                            .cappedFont(.subheadline, maxDynamicType: .accessibility1)
                            .foregroundColor(Color(NCBrandColor.shared.customer))
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, contentPadding)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, -20)
            }
        }
    }
}

//#if DEBUG
//#Preview {
//    NavigationView {
//        NoAlbumsEmptyView(onNewAlbumCreationIntent: {})
//            .navigationTitle("Album")
//            .navigationBarTitleDisplayMode(.inline)
//    }
//}
//#endif


#if DEBUG
struct NoAlbumsEmptyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoAlbumsEmptyView(
                onNewAlbumCreationIntent: {}
            )
            .navigationTitle("Albums")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
#endif
