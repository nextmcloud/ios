//
//  NCLoadingAlert.swift
//  Nextcloud
//
//  Created by Dhanesh on 05/08/25.
//  Copyright © 2025 Marino Faggiana. All rights reserved.
//

import SwiftUI

struct NCLoadingAlert: View {
    
    var body: some View {
        
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            ProgressView("Wait a moment...")
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
        }
    }
}

//#if DEBUG
//#Preview {
//    NCLoadingAlert()
//}
//#endif
