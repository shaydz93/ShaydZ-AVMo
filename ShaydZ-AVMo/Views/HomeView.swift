import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VirtualEnvironmentView()
                .tabItem {
                    Image(systemName: "display")
                    Text("Virtual Desktop")
                }
                .tag(0)
            
            AppLibraryView()
                .tabItem {
                    Image(systemName: "square.grid.2x2")
                    Text("Apps")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
