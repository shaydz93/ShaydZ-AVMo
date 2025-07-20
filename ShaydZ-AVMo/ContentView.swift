import SwiftUI

struct ContentView: View {
    var body: some View {
        // DEBUG MODE: Skip all authentication and show debug interface  
        HomeView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
