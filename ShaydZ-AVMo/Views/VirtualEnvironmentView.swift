import SwiftUI

struct VirtualEnvironmentView: View {
    @StateObject private var viewModel = VirtualEnvironmentViewModel()
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Connection status bar
                HStack {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(viewModel.connectionStatus)
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Latency: \(viewModel.latency)ms")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        viewModel.toggleConnection()
                    }) {
                        Image(systemName: viewModel.isConnected ? "pause.circle" : "play.circle")
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.3))
                
                if viewModel.isConnected {
                    // Virtual environment screen
                    VStack {
                        // Mock Android interface
                        VirtualAndroidView()
                            .cornerRadius(4)
                    }
                    .padding(5)
                } else {
                    // Connection prompt
                    VStack(spacing: 20) {
                        Image(systemName: "network.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("Virtual Environment Not Connected")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Press the connect button to start your secure virtual session")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        Button(action: {
                            viewModel.toggleConnection()
                        }) {
                            Text("Connect")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Control bar
                HStack(spacing: 40) {
                    Button(action: {
                        // Home action
                    }) {
                        Image(systemName: "house.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Back action
                    }) {
                        Image(systemName: "arrow.left")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        // Recent apps action
                    }) {
                        Image(systemName: "square.grid.2x2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.3))
            }
        }
    }
}

struct VirtualAndroidView: View {
    var body: some View {
        // This is a mock Android interface
        ZStack {
            Image("android_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .overlay(
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                )
            
            VStack(spacing: 20) {
                // Status bar
                HStack {
                    Spacer()
                    Text("12:00")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wifi")
                        Image(systemName: "battery.100")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.leading, 8)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                
                Spacer()
                
                // App icons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    ForEach(0..<8) { index in
                        VStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: mockAppIcons[index % mockAppIcons.count])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                            }
                            
                            Text(mockAppNames[index % mockAppNames.count])
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Dock
                HStack(spacing: 20) {
                    ForEach(0..<4) { index in
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: mockDockIcons[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.vertical)
        }
    }
    
    // Mock data
    private let mockAppIcons = ["envelope.fill", "safari.fill", "camera.fill", "music.note", 
                              "doc.fill", "calendar", "photos", "gear"]
    
    private let mockAppNames = ["Email", "Browser", "Camera", "Music", 
                             "Documents", "Calendar", "Photos", "Settings"]
    
    private let mockDockIcons = ["phone.fill", "message.fill", "safari.fill", "folder.fill"]
}

struct VirtualEnvironmentView_Previews: PreviewProvider {
    static var previews: some View {
        VirtualEnvironmentView()
    }
}
