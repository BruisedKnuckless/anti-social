import SwiftUI
import FamilyControls

@main
struct AntiSocialApp: App {
    @StateObject private var blocker = AppBlocker()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(blocker)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var blocker: AppBlocker
    @StateObject private var web = WebViewModel()
    @State private var showBlockSettings = false

    var body: some View {
        NavigationStack {
            WebViewContainer(webView: web.webView)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    if web.isLoading { ProgressView().padding(.top, 8) }
                }
                .navigationTitle("Instagram · no reels")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button { web.webView.goBack() } label: { Image(systemName: "chevron.left") }
                            .disabled(!web.canGoBack)
                        Button { web.goHome() } label: { Image(systemName: "house") }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button { web.webView.reload() } label: { Image(systemName: "arrow.clockwise") }
                        Button { showBlockSettings = true } label: {
                            Image(systemName: blocker.isBlocking ? "lock.shield.fill" : "lock.shield")
                        }
                    }
                }
        }
        .sheet(isPresented: $showBlockSettings) {
            BlockSettingsView().environmentObject(blocker)
        }
    }
}

/// Lets you pick the native Instagram app and shield it with Screen Time.
struct BlockSettingsView: View {
    @EnvironmentObject private var blocker: AppBlocker
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Block the native Instagram app so you use this reel-free version instead. DMs, stories, profiles and posting still work here.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if !blocker.isAuthorized {
                    Section {
                        Button("Allow Screen Time access") {
                            Task { await blocker.requestAuthorization() }
                        }
                    }
                } else {
                    Section("Step 1") {
                        Button { showPicker = true } label: {
                            Label(blocker.hasSelection
                                  ? "Instagram selected — change"
                                  : "Choose Instagram from your apps",
                                  systemImage: "apps.iphone")
                        }
                    }
                    Section("Step 2") {
                        Toggle("Block native Instagram app", isOn: Binding(
                            get: { blocker.isBlocking },
                            set: { blocker.setBlocking($0) }
                        ))
                        .disabled(!blocker.hasSelection)
                    }
                }
            }
            .navigationTitle("Block Instagram app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .familyActivityPicker(isPresented: $showPicker, selection: $blocker.selection)
        }
    }
}
