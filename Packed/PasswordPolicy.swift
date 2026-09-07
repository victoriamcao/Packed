//
//  PasswordPolicy.swift
//  Packed
//
//  The single source of truth for what makes a valid password, shared by
//  SignupFormView and ChangePasswordView so both enforce (and display)
//  the exact same rules.
//

import Foundation

enum PasswordPolicy {
    static let minimumLength = 8

    static func hasMinimumLength(_ password: String) -> Bool {
        password.count >= minimumLength
    }

    static func hasNumber(_ password: String) -> Bool {
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    static func hasSpecialCharacter(_ password: String) -> Bool {
        password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*")) != nil
    }

    static func isValid(_ password: String) -> Bool {
        hasMinimumLength(password) && hasNumber(password) && hasSpecialCharacter(password)
    }
}
