//
//  ContentView.swift
//  HelloAssumeRole
//
//  Created by Kaz Yoshikawa on 2024/06/22.
//

import SwiftUI

struct ContentView: View {

	let contentsManager = ContentManager.shared
	
	@State var items = [ContentManager.Item]()
	@State var loadingCount = 0
	var body: some View {
		NavigationStack {
			VStack {
				List (self.items, id: \.self) { item in
					HStack {
						VStack {
							Text(item.uuid.uuidString)
							Text(item.timestampString)
						}
						Spacer()
						Button {
							self.deleteItem(item)
						} label: {
							Image(systemName: "trash")
						}

					}
				}
			}
			.toolbar {
				Button {
					self.reload()
				} label: {
					Image(systemName: "arrow.clockwise")
				}
				Button {
					Task {
						do {
							let item = ContentManager.Item(uuid: UUID(), timestamp: Date())
							try await self.contentsManager.putItem(item)
							self.reload()
						}
						catch {
							print("\(error)")
						}
					}
				} label: {
					Image(systemName: "plus")
				}
			}
		}
		.onAppear() {
			self.reload()
		}
		#if os(iOS)
		.navigationBarHidden(false)
		#endif
		.navigationTitle("Hello Assume Role")
		.overlay {
			if self.loadingCount > 0 {
				ProgressView("Now loading...")
			}
		}
	}
	func deleteItem(_ item: ContentManager.Item) {
		Task {
			self.loadingCount += 1
			defer { self.loadingCount -= 1 }
			do {
				try await self.contentsManager.deleteItem(item)
				self.reload()
			}
			catch {
				print("\(error)")
			}
		}
	}
	func reload() {
		Task {
			self.loadingCount += 1
			defer { self.loadingCount -= 1 }
			do {
				let items = try await contentsManager.allItems()
				self.items = items.sorted(by: { $0.timestamp < $1.timestamp })
			}
			catch {
				print("\(error)")
			}
		}
	}
}

#Preview {
	ContentView()
}
