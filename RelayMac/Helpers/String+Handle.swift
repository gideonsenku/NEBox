//
//  String+Handle.swift
//  RelayMac
//

import Foundation

extension String {
    /// Presentational handle: ensures exactly one leading `@`, preserving the
    /// default `@anonymous` (which already carries `@`) without double-prefixing.
    /// Empty strings are returned unchanged so callers can decide how to render them.
    var asHandle: String {
        guard !isEmpty else { return self }
        return hasPrefix("@") ? self : "@\(self)"
    }
}
