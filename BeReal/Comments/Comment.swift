//
//  Comment.swift
//  BeReal
//
//  Created by Andy Espinoza on 3/1/26.
//

import Foundation
import ParseSwift

struct Comment: ParseObject {
    // ParseObject required
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom fields
    var text: String?
    var user: User?
    var post: Post?
}
