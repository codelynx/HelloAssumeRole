//
//  HelloAssumeRoleApp.swift
//  HelloAssumeRole
//
//  Created by Kaz Yoshikawa on 2024/06/22.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
typealias XApplicationDelegate = UIApplicationDelegate
#elseif canImport(AppKit)
import AppKit
typealias XApplicationDelegate = NSApplicationDelegate
#endif


class AppDelegate: NSObject, XApplicationDelegate {
#if os(iOS)
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		return true
	}
#elseif os(macOS)
	func applicationDidFinishLaunching(_ notification: Notification) {
	}
#endif
}


@main
struct HelloAssumeRoleApp: App {
#if os(iOS)
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#elseif os(macOS)
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
