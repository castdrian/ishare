//
//  LocalizableManager.swift
//  ishare
//
//  Created by Adrian Castro on 16/1/25.
//

import Defaults
import Foundation
import SwiftUI

enum LanguageTypes: String, CaseIterable, RawRepresentable, Defaults.Serializable {
	case english = "en"
	case arabic = "ar"
	case chinese = "zh-CN"
	case french = "fr"
	case german = "de"
	case hindi = "hi"
	case japanese = "ja"
	case korean = "ko"
	case spanish = "es"
	case turkish = "tr"
	case ukrainian = "uk"

	var name: String {
		switch self {
		case .english: "English"
		case .arabic: "عربي"
		case .chinese: "中文"
		case .french: "Français"
		case .german: "Deutsch"
		case .hindi: "हिन्दी"
		case .japanese: "日本語"
		case .korean: "한국어"
		case .spanish: "Español"
		case .turkish: "Türkçe"
		case .ukrainian: "Українська"
		}
	}
}

@MainActor
extension Bundle {
	private static var bundle: Bundle!

	static func setLanguage(language: String) {
		let path = Bundle.main.path(forResource: language, ofType: "lproj")
		bundle = path != nil ? Bundle(path: path!) : Bundle.main
	}

	static func localizedBundle() -> Bundle {
		bundle ?? Bundle.main
	}
}

extension String {
	@MainActor func localized() -> String {
		Bundle.localizedBundle().localizedString(forKey: self, value: nil, table: nil)
	}
}

@MainActor
class LocalizableManager: ObservableObject {
	static let shared = LocalizableManager()

	@Default(.storedLanguage) var storedLanguage

	@Published var currentLanguage: LanguageTypes = .english {
		didSet {
			storedLanguage = currentLanguage
			Bundle.setLanguage(language: currentLanguage.rawValue)
		}
	}

	@Published var showRestartAlert = false
	private var pendingLanguage: LanguageTypes?

	func changeLanguage(to language: LanguageTypes) {
		guard language != currentLanguage else { return }
		pendingLanguage = language
		showRestartAlert = true
	}

	func confirmLanguageChange() {
		guard let newLanguage = pendingLanguage else { return }
		currentLanguage = newLanguage
		Task { @MainActor in
			NSApplication.shared.terminate(nil)
		}
	}

	private init() {
		currentLanguage = storedLanguage
		Bundle.setLanguage(language: storedLanguage.rawValue)
	}
}
