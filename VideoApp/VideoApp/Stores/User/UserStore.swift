//
//  Copyright (C) 2019 Twilio, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

protocol UserStoreReading: AnyObject {
    var user: User { get }
}

class UserStore: UserStoreReading {
    var user: User {
        User(displayName: appSettingsStore.userIdentity.nilIfEmpty ?? authStore.userDisplayName, id: UUID().uuidString)
    }
    private let appSettingsStore: AppSettingsStoreWriting
    private let authStore: AuthStoreReading

    init(appSettingsStore: AppSettingsStoreWriting, authStore: AuthStoreReading) {
        self.appSettingsStore = appSettingsStore
        self.authStore = authStore
    }
}
