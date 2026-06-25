import SwiftUI

@main
struct MuzeebraApp: App {
    @State private var store = SpotifyStore()
    
    var body: some Scene {
        WindowGroup {
            MenuBarView(store: store)
                .frame(
                    minWidth: 320,
                    idealWidth: store.isMiniPlayerMode ? 320 : 320,
                    maxWidth: store.isMiniPlayerMode ? 320 : .infinity,
                    minHeight: store.isMiniPlayerMode ? 110 : 450,
                    idealHeight: store.isMiniPlayerMode ? 110 : 450,
                    maxHeight: store.isMiniPlayerMode ? 110 : .infinity
                )
        }
    }
}
