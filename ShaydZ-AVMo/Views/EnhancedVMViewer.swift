import SwiftUI
import Combine
import WebKit

/// Enhanced VM Viewer with SPICE protocol support inspired by UTM
struct EnhancedVMViewer: View {
    let vmInstance: UTMEnhancedVirtualMachineService.VMInstance
    @StateObject private var viewModel = EnhancedVMViewerViewModel()
    @State private var showingControls = false
    @State private var isFullScreen = false
    @State private var showingSettings = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // VM Display
                VMDisplayView(
                    connectionInfo: vmInstance.connectionInfo,
                    displayConfig: vmInstance.config.displays.first,
                    viewModel: viewModel
                )
                .clipped()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingControls.toggle()
                    }
                }
                
                // Control Overlay
                if showingControls {
                    VStack {
                        // Top Control Bar
                        HStack {
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            // Performance Indicator
                            HStack(spacing: 8) {
                                performanceIndicator(
                                    title: "FPS",
                                    value: "\(vmInstance.performance.frameRate)",
                                    color: vmInstance.performance.frameRate >= 30 ? .green : .orange
                                )
                                
                                performanceIndicator(
                                    title: "CPU",
                                    value: "\(Int(vmInstance.performance.cpuUsage))%",
                                    color: vmInstance.performance.cpuUsage < 80 ? .green : .red
                                )
                                
                                performanceIndicator(
                                    title: "MEM",
                                    value: "\(Int(vmInstance.performance.memoryUsage))%",
                                    color: vmInstance.performance.memoryUsage < 90 ? .green : .red
                                )
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            
                            Spacer()
                            
                            Button(action: toggleFullScreen) {
                                Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Bottom Control Bar
                        VStack(spacing: 12) {
                            // VM Control Buttons
                            HStack(spacing: 20) {
                                vmControlButton(
                                    icon: "pause.fill",
                                    title: "Pause",
                                    action: { viewModel.pauseVM(vmInstance.id) }
                                )
                                
                                vmControlButton(
                                    icon: "camera.fill",
                                    title: "Screenshot",
                                    action: { viewModel.takeScreenshot(vmInstance.id) }
                                )
                                
                                vmControlButton(
                                    icon: "photo.on.rectangle.angled",
                                    title: "Snapshot",
                                    action: { viewModel.takeSnapshot(vmInstance.id) }
                                )
                                
                                vmControlButton(
                                    icon: "keyboard",
                                    title: "Keyboard",
                                    action: { viewModel.toggleVirtualKeyboard() }
                                )
                            }
                            
                            // Android-specific controls
                            if vmInstance.config.androidConfig.androidVersion.isEmpty == false {
                                HStack(spacing: 20) {
                                    androidControlButton(
                                        icon: "arrow.left",
                                        title: "Back",
                                        action: { viewModel.sendAndroidKey(.back) }
                                    )
                                    
                                    androidControlButton(
                                        icon: "house",
                                        title: "Home",
                                        action: { viewModel.sendAndroidKey(.home) }
                                    )
                                    
                                    androidControlButton(
                                        icon: "rectangle.stack",
                                        title: "Recent",
                                        action: { viewModel.sendAndroidKey(.recent) }
                                    )
                                    
                                    androidControlButton(
                                        icon: "speaker.wave.2",
                                        title: "Volume",
                                        action: { viewModel.showVolumeControls() }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .background(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color.clear, location: 0),
                                    .init(color: Color.black.opacity(0.8), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .transition(.opacity)
                }
                
                // Status Overlay
                if let status = viewModel.statusMessage {
                    VStack {
                        Spacer()
                        Text(status)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                    }
                    .transition(.move(edge: .bottom))
                }
                
                // Virtual Keyboard
                if viewModel.showingVirtualKeyboard {
                    VStack {
                        Spacer()
                        VirtualKeyboardView(onKeyPressed: viewModel.sendKeyInput)
                            .transition(.move(edge: .bottom))
                    }
                }
            }
            .navigationBarHidden(isFullScreen)
            .statusBarHidden(isFullScreen)
        }
        .sheet(isPresented: $showingSettings) {
            VMSettingsView(vmInstance: vmInstance, viewModel: viewModel)
        }
        .onAppear {
            viewModel.connectToVM(vmInstance)
            
            // Auto-hide controls after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingControls = false
                }
            }
        }
        .alert("VM Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - Helper Views
    
    private func performanceIndicator(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func vmControlButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 60, height: 50)
        }
    }
    
    private func androidControlButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 50, height: 40)
        }
    }
    
    private func toggleFullScreen() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFullScreen.toggle()
        }
    }
}

/// VM Display View with WebKit for SPICE/VNC
struct VMDisplayView: UIViewRepresentable {
    let connectionInfo: UTMEnhancedVirtualMachineService.VMInstance.ConnectionInfo?
    let displayConfig: UTMEnhancedVMConfig.DisplayConfig?
    let viewModel: EnhancedVMViewerViewModel
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let connectionInfo = connectionInfo else { return }
        
        // Create SPICE HTML client
        let spiceHTML = createSPICEClient(connectionInfo: connectionInfo)
        
        webView.loadHTMLString(spiceHTML, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: VMDisplayView
        
        init(_ parent: VMDisplayView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.viewModel.onDisplayConnected()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.onDisplayError(error.localizedDescription)
        }
    }
    
    /// Create SPICE HTML client
    private func createSPICEClient(connectionInfo: UTMEnhancedVirtualMachineService.VMInstance.ConnectionInfo) -> String {
        let spicePort = connectionInfo.spicePort ?? 5930
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>VM Display</title>
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: black;
                    overflow: hidden;
                }
                #display {
                    width: 100vw;
                    height: 100vh;
                    object-fit: contain;
                    background: black;
                }
                .loading {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    color: white;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
            </style>
        </head>
        <body>
            <div class="loading" id="loading">Connecting to VM...</div>
            <canvas id="display" style="display: none;"></canvas>
            
            <script>
                // SPICE HTML5 client implementation
                class SPICEClient {
                    constructor(canvas) {
                        this.canvas = canvas;
                        this.ctx = canvas.getContext('2d');
                        this.socket = null;
                        this.connected = false;
                    }
                    
                    connect(host, port) {
                        try {
                            this.socket = new WebSocket(`ws://${host}:${port}`);
                            this.socket.binaryType = 'arraybuffer';
                            
                            this.socket.onopen = () => {
                                console.log('SPICE connected');
                                this.connected = true;
                                document.getElementById('loading').style.display = 'none';
                                this.canvas.style.display = 'block';
                                this.startDisplay();
                            };
                            
                            this.socket.onmessage = (event) => {
                                this.handleMessage(event.data);
                            };
                            
                            this.socket.onclose = () => {
                                console.log('SPICE disconnected');
                                this.connected = false;
                                this.showError('Connection lost');
                            };
                            
                            this.socket.onerror = (error) => {
                                console.error('SPICE error:', error);
                                this.showError('Connection failed');
                            };
                        } catch (error) {
                            console.error('Failed to connect:', error);
                            this.showError('Failed to connect to VM');
                        }
                    }
                    
                    handleMessage(data) {
                        // Handle SPICE protocol messages
                        // This is a simplified implementation
                        if (data instanceof ArrayBuffer) {
                            // Process binary display data
                            this.updateDisplay(data);
                        }
                    }
                    
                    updateDisplay(data) {
                        // Update canvas with VM display data
                        // This would decode SPICE display data in a real implementation
                        this.drawFrame(data);
                    }
                    
                    drawFrame(data) {
                        // Simulate drawing VM display
                        this.ctx.fillStyle = '#1a1a1a';
                        this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
                        
                        // Draw Android-like interface simulation
                        this.drawAndroidInterface();
                    }
                    
                    drawAndroidInterface() {
                        const width = this.canvas.width;
                        const height = this.canvas.height;
                        
                        // Status bar
                        this.ctx.fillStyle = '#2196F3';
                        this.ctx.fillRect(0, 0, width, 60);
                        
                        // App icons simulation
                        const iconSize = 80;
                        const cols = Math.floor(width / (iconSize + 20));
                        const rows = Math.floor((height - 200) / (iconSize + 20));
                        
                        for (let row = 0; row < Math.min(rows, 4); row++) {
                            for (let col = 0; col < Math.min(cols, 4); col++) {
                                const x = 20 + col * (iconSize + 20);
                                const y = 100 + row * (iconSize + 20);
                                
                                // Draw app icon
                                this.ctx.fillStyle = `hsl(${(row * cols + col) * 45}, 70%, 60%)`;
                                this.ctx.beginPath();
                                this.ctx.roundRect(x, y, iconSize, iconSize, 10);
                                this.ctx.fill();
                                
                                // Draw app name
                                this.ctx.fillStyle = 'white';
                                this.ctx.font = '12px -apple-system';
                                this.ctx.textAlign = 'center';
                                this.ctx.fillText(`App ${row * cols + col + 1}`, x + iconSize/2, y + iconSize + 15);
                            }
                        }
                        
                        // Navigation bar
                        this.ctx.fillStyle = '#1a1a1a';
                        this.ctx.fillRect(0, height - 80, width, 80);
                        
                        // Navigation buttons
                        const navButtons = ['◀', '●', '■'];
                        const buttonWidth = width / 3;
                        navButtons.forEach((button, index) => {
                            this.ctx.fillStyle = 'white';
                            this.ctx.font = '24px -apple-system';
                            this.ctx.textAlign = 'center';
                            this.ctx.fillText(button, (index + 0.5) * buttonWidth, height - 30);
                        });
                    }
                    
                    startDisplay() {
                        // Resize canvas to match display config
                        this.resizeCanvas();
                        
                        // Start display update loop
                        this.displayLoop();
                    }
                    
                    resizeCanvas() {
                        const rect = this.canvas.getBoundingClientRect();
                        this.canvas.width = rect.width * window.devicePixelRatio;
                        this.canvas.height = rect.height * window.devicePixelRatio;
                        this.ctx.scale(window.devicePixelRatio, window.devicePixelRatio);
                    }
                    
                    displayLoop() {
                        if (this.connected) {
                            this.drawFrame();
                            requestAnimationFrame(() => this.displayLoop());
                        }
                    }
                    
                    showError(message) {
                        document.getElementById('loading').textContent = message;
                        document.getElementById('loading').style.display = 'block';
                        this.canvas.style.display = 'none';
                    }
                    
                    sendMouseEvent(type, x, y, button = 0) {
                        if (this.connected && this.socket) {
                            const event = {
                                type: 'mouse',
                                action: type,
                                x: x,
                                y: y,
                                button: button
                            };
                            this.socket.send(JSON.stringify(event));
                        }
                    }
                    
                    sendKeyEvent(type, keyCode) {
                        if (this.connected && this.socket) {
                            const event = {
                                type: 'key',
                                action: type,
                                keyCode: keyCode
                            };
                            this.socket.send(JSON.stringify(event));
                        }
                    }
                }
                
                // Initialize SPICE client
                const canvas = document.getElementById('display');
                const client = new SPICEClient(canvas);
                
                // Connect to SPICE server
                client.connect('localhost', '${spicePort}');
                
                // Handle touch/mouse events
                canvas.addEventListener('touchstart', (e) => {
                    e.preventDefault();
                    const rect = canvas.getBoundingClientRect();
                    const touch = e.touches[0];
                    const x = (touch.clientX - rect.left) * (canvas.width / rect.width);
                    const y = (touch.clientY - rect.top) * (canvas.height / rect.height);
                    client.sendMouseEvent('down', x, y, 1);
                });
                
                canvas.addEventListener('touchend', (e) => {
                    e.preventDefault();
                    client.sendMouseEvent('up', 0, 0, 1);
                });
                
                canvas.addEventListener('touchmove', (e) => {
                    e.preventDefault();
                    const rect = canvas.getBoundingClientRect();
                    const touch = e.touches[0];
                    const x = (touch.clientX - rect.left) * (canvas.width / rect.width);
                    const y = (touch.clientY - rect.top) * (canvas.height / rect.height);
                    client.sendMouseEvent('move', x, y, 1);
                });
                
                // Handle keyboard events
                window.addEventListener('keydown', (e) => {
                    client.sendKeyEvent('down', e.keyCode);
                });
                
                window.addEventListener('keyup', (e) => {
                    client.sendKeyEvent('up', e.keyCode);
                });
                
                // Handle window resize
                window.addEventListener('resize', () => {
                    client.resizeCanvas();
                });
            </script>
        </body>
        </html>
        """
    }
}

/// Virtual Keyboard View
struct VirtualKeyboardView: View {
    let onKeyPressed: (String) -> Void
    
    private let keyboardRows = [
        ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"],
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["Z", "X", "C", "V", "B", "N", "M"]
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(keyboardRows.enumerated()), id: \\.offset) { index, row in
                HStack(spacing: 6) {
                    if index == 3 {
                        keyboardKey("⇧", width: 50)
                    }
                    
                    ForEach(row, id: \\.self) { key in
                        keyboardKey(key)
                    }
                    
                    if index == 3 {
                        keyboardKey("⌫", width: 50)
                    }
                }
            }
            
            // Bottom row
            HStack(spacing: 6) {
                keyboardKey("123", width: 60)
                keyboardKey("Space", width: 180)
                keyboardKey("Return", width: 80)
            }
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .padding()
    }
    
    private func keyboardKey(_ text: String, width: CGFloat = 35) -> some View {
        Button(action: { onKeyPressed(text) }) {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: width, height: 40)
                .background(Color.gray.opacity(0.6))
                .cornerRadius(8)
        }
    }
}

/// VM Settings View
struct VMSettingsView: View {
    let vmInstance: UTMEnhancedVirtualMachineService.VMInstance
    let viewModel: EnhancedVMViewerViewModel
    @Environment(\\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Display") {
                    HStack {
                        Text("Resolution")
                        Spacer()
                        Text("\\(vmInstance.config.displays.first?.width ?? 0) × \\(vmInstance.config.displays.first?.height ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("GPU Acceleration")
                        Spacer()
                        Image(systemName: vmInstance.config.displays.first?.hasGLAcceleration == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(vmInstance.config.displays.first?.hasGLAcceleration == true ? .green : .red)
                    }
                }
                
                Section("Performance") {
                    performanceRow("CPU Usage", "\\(Int(vmInstance.performance.cpuUsage))%")
                    performanceRow("Memory Usage", "\\(Int(vmInstance.performance.memoryUsage))%")
                    performanceRow("Frame Rate", "\\(vmInstance.performance.frameRate) FPS")
                    performanceRow("Latency", "\\(vmInstance.performance.latency) ms")
                }
                
                Section("Android") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(vmInstance.config.androidConfig.androidVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Google Play")
                        Spacer()
                        Image(systemName: vmInstance.config.androidConfig.isGooglePlayEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(vmInstance.config.androidConfig.isGooglePlayEnabled ? .green : .red)
                    }
                }
                
                Section("Security") {
                    HStack {
                        Text("Secure Boot")
                        Spacer()
                        Image(systemName: vmInstance.config.security.hasSecureBoot ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(vmInstance.config.security.hasSecureBoot ? .green : .gray)
                    }
                    
                    HStack {
                        Text("Encryption")
                        Spacer()
                        Image(systemName: vmInstance.config.security.hasEncryption ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(vmInstance.config.security.hasEncryption ? .green : .gray)
                    }
                    
                    HStack {
                        Text("Isolation Level")
                        Spacer()
                        Text(vmInstance.config.security.isolationLevel.capitalized)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Actions") {
                    Button("Take Screenshot") {
                        viewModel.takeScreenshot(vmInstance.id)
                        dismiss()
                    }
                    
                    Button("Create Snapshot") {
                        viewModel.takeSnapshot(vmInstance.id)
                        dismiss()
                    }
                    
                    Button("Reset VM", role: .destructive) {
                        viewModel.resetVM(vmInstance.id)
                        dismiss()
                    }
                }
            }
            .navigationTitle("VM Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performanceRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    let config = UTMEnhancedVMConfig(
        id: "preview",
        name: "Preview VM",
        architecture: .aarch64,
        target: "virt",
        memorySize: 4096,
        cpuCount: 4,
        hasHypervisor: true,
        hasUefiBoot: true,
        hasTPMDevice: true,
        hasRNGDevice: true,
        hasBalloonDevice: true,
        hasRTCLocalTime: false,
        displays: [
            UTMEnhancedVMConfig.DisplayConfig(
                hardware: "virtio-gpu-gl-pci",
                width: 1080,
                height: 2400,
                isDynamicResolution: true,
                hasGLAcceleration: true
            )
        ],
        networks: [],
        drives: [],
        serials: [],
        sound: [],
        sharing: UTMEnhancedVMConfig.SharingConfig(
            hasClipboardSharing: true,
            directoryShareMode: "virtfs",
            isDirectoryShareReadOnly: false,
            sharedDirectoryURL: nil
        ),
        security: UTMEnhancedVMConfig.SecurityConfig(
            hasSecureBoot: true,
            hasEncryption: true,
            isolationLevel: "high",
            networkIsolation: true
        ),
        androidConfig: UTMEnhancedVMConfig.AndroidVMConfig(
            androidVersion: "13.0",
            isGooglePlayEnabled: true,
            hasGoogleServices: true,
            deviceProfile: "pixel",
            orientation: "portrait",
            isRooted: false,
            customApps: []
        )
    )
    
    let instance = UTMEnhancedVirtualMachineService.VMInstance(
        id: "preview",
        config: config,
        state: .running,
        connectionInfo: UTMEnhancedVirtualMachineService.VMInstance.ConnectionInfo(
            websocketURL: "ws://localhost:8082",
            vncPort: 5900,
            spicePort: 5930,
            androidPort: 5555
        ),
        performance: UTMEnhancedVirtualMachineService.VMInstance.PerformanceMetrics(
            cpuUsage: 45.0,
            memoryUsage: 68.0,
            networkIO: (sent: 1024, received: 2048),
            diskIO: (read: 512, written: 256),
            frameRate: 60,
            latency: 25
        ),
        lastActivity: Date()
    )
    
    EnhancedVMViewer(vmInstance: instance)
}
