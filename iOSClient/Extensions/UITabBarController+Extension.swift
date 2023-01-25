//
<<<<<<<< HEAD:iOSClient/Main/NCCellProtocol.swift
//  NCCellProtocol.swift
//  Nextcloud
//
//  Created by Philippe Weidmann on 05.06.20.
//  Copyright © 2020 Marino Faggiana. All rights reserved.
========
//  UITabBarController+Extension.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 02/08/2022.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
>>>>>>>> a59041f2270971574b9795d3e9eebb4da7cea5a4:iOSClient/Extensions/UITabBarController+Extension.swift
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

<<<<<<<< HEAD:iOSClient/Main/NCCellProtocol.swift
protocol NCCellProtocol {
    var fileAvatarImageView: UIImageView? { get }
    var fileObjectId: String? { get }
    var filePreviewImageView: UIImageView? { get }
    var fileUser: String? { get }
========
extension UITabBarController {

    // https://stackoverflow.com/questions/6131205/how-to-find-topmost-view-controller-on-ios
    override func topMostViewController() -> UIViewController {
        return self.selectedViewController!.topMostViewController()
    }
>>>>>>>> a59041f2270971574b9795d3e9eebb4da7cea5a4:iOSClient/Extensions/UITabBarController+Extension.swift
}
