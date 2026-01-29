//
// Copyright (c) 2023 Marcel Müller <marcel-mueller@gmx.de>
//
// Author Marcel Müller <marcel-mueller@gmx.de>
//
// GNU GPL version 3 or any later version
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import UIKit

///
/// Immutable test configuration.
///
enum TestConstants {
    ///
    /// The default number of seconds to wait for the appearance of user interface controls during user interface tests.
    ///
    static let controlExistenceTimeout: Double = 10

    ///
    /// The full base URL for the server to run against.
    ///
    static let server = "http://localhost:8080"

    ///
    /// Default user name to sign in with.
    ///
    static let username = "admin"

    ///
    /// Password of the default user name to sign in with.
    ///
    static let password = "admin"

    ///
    /// Account identifier of the default user to test with.
    ///
    static let account = "\(username) \(server)"
}
