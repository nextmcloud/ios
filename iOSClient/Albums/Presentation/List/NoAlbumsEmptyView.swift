// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2026 Dhanesh
// SPDX-FileCopyrightText: 2026 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import SwiftUI

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
                        .cappedFont(.headline, maxDynamicType: .accessibility2)

                    Text(NSLocalizedString("_albums_list_empty_subheading_", comment: ""))
                        .cappedFont(.subheadline, maxDynamicType: .accessibility1)
                        .foregroundColor(.secondary)

                    Button(action: onNewAlbumCreationIntent) {
                        Label(NSLocalizedString("_albums_list_empty_new_album_btn_", comment: ""), systemImage: "plus")
                            .cappedFont(.subheadline, maxDynamicType: .accessibility1)
                            .foregroundColor(Color(NCBrandColor.shared.customer))
                    }
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, contentPadding)
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 30)
            }
        }
    }
}

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
