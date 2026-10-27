//
//  AppLinks.swift
//  Packed
//
//  External links shown in the app. Update privacyPolicy once GitHub Pages
//  (or wherever you host it) is set up - see docs/privacy-policy.md.
//

import Foundation

enum AppLinks {
    static let privacyPolicy = URL(string: "https://victoriamcao.github.io/Packed/privacy-policy")
        ?? URL(fileURLWithPath: "/")
}
