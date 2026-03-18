import Cocoa
import MetalKit
import UniformTypeIdentifiers

struct DisplayParams {
    var scanlineEnabled: UInt32
    var sourceHeight: UInt32
    var backingScale: Float
    var filterType: UInt32
    var textureWidth: Float
    var textureHeight: Float
}

class EmulatorView: MTKView, MTKViewDelegate {

    private let bridge: EmulatorBridge
    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var texture: MTLTexture?
    private var vertexBuffer: MTLBuffer?
    private var nearestSamplerState: MTLSamplerState?
    private var linearSamplerState: MTLSamplerState?
    private var paramsBuffer: MTLBuffer?

    weak var statusBarView: StatusBarView?

    // Frame pacing
    private var emulationStartTime: CFTimeInterval = 0
    private var emulatedTime: CFTimeInterval = 0
    private var frameInterval: CFTimeInterval = 0

    // FPS counter
    private var fpsFrameCount: Int = 0
    private var fpsLastTime: CFTimeInterval = 0
    private var currentFPS: Double = 0

    init(frame: NSRect, device: MTLDevice, bridge: EmulatorBridge) {
        self.bridge = bridge
        super.init(frame: frame, device: device)
        self.delegate = self
        self.preferredFramesPerSecond = 60
        self.colorPixelFormat = .bgra8Unorm
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        setupMetal()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupMetal() {
        guard let device = self.device else { return }

        commandQueue = device.makeCommandQueue()

        // Create shader library
        guard let library = device.makeDefaultLibrary() else {
            NSLog("Failed to create default Metal library, using basic rendering")
            createFallbackPipeline(device: device)
            return
        }

        let vertexFunction = library.makeFunction(name: "vertexShader")
        let fragmentFunction = library.makeFunction(name: "fragmentShader")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat

        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            NSLog("Failed to create pipeline state: \(error)")
            createFallbackPipeline(device: device)
        }

        // Create vertex buffer for full-screen quad
        let vertices: [Float] = [
            // positions    // texcoords
            -1.0, -1.0,    0.0, 1.0,
             1.0, -1.0,    1.0, 1.0,
            -1.0,  1.0,    0.0, 0.0,
             1.0,  1.0,    1.0, 0.0,
        ]
        vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.stride, options: .storageModeShared)

        // Create params buffer for shader uniforms
        var params = DisplayParams(scanlineEnabled: 0, sourceHeight: 400, backingScale: 1.0, filterType: 0, textureWidth: 640.0, textureHeight: 400.0)
        paramsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<DisplayParams>.stride, options: .storageModeShared)

        // Create samplers
        let nearestDesc = MTLSamplerDescriptor()
        nearestDesc.minFilter = .nearest
        nearestDesc.magFilter = .nearest
        nearestDesc.sAddressMode = .clampToEdge
        nearestDesc.tAddressMode = .clampToEdge
        nearestSamplerState = device.makeSamplerState(descriptor: nearestDesc)

        let linearDesc = MTLSamplerDescriptor()
        linearDesc.minFilter = .linear
        linearDesc.magFilter = .linear
        linearDesc.sAddressMode = .clampToEdge
        linearDesc.tAddressMode = .clampToEdge
        linearSamplerState = device.makeSamplerState(descriptor: linearDesc)
    }

    private func createFallbackPipeline(device: MTLDevice) {
        // Create a simple shader inline for fallback
        let shaderSource = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexOut {
            float4 position [[position]];
            float2 texCoord;
        };

        vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                                       constant float4 *vertices [[buffer(0)]]) {
            VertexOut out;
            float4 v = vertices[vertexID];
            out.position = float4(v.xy, 0.0, 1.0);
            out.texCoord = v.zw;
            return out;
        }

        fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                        texture2d<float> tex [[texture(0)]],
                                        sampler s [[sampler(0)]]) {
            float4 color = tex.sample(s, in.texCoord);
            return float4(color.rgb, 1.0);
        }
        """

        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertexShader")
            pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
            pipelineDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            NSLog("Failed to create fallback pipeline: \(error)")
        }
    }

    private func updateTexture() {
        guard let device = self.device else { return }
        guard let buffer = bridge.screenBuffer() else { return }

        let width = Int(bridge.screenWidth)
        let height = Int(bridge.screenHeight)

        guard width > 0 && height > 0 else { return }

        // Create or recreate texture if size changed
        if texture?.width != width || texture?.height != height {
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: width,
                height: height,
                mipmapped: false
            )
            descriptor.usage = .shaderRead
            texture = device.makeTexture(descriptor: descriptor)
        }

        guard let texture = texture else { return }

        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: width, height: height, depth: 1))
        texture.replace(region: region, mipmapLevel: 0,
                        withBytes: buffer,
                        bytesPerRow: width * MemoryLayout<UInt32>.stride)
    }

    // MARK: - Timing Control

    func resetEmulationTiming() {
        emulationStartTime = 0
        emulatedTime = 0
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Notify OSD of host window size for screen filter power calculation
        // Use logical size (points), not physical pixels
        let logicalSize = view.bounds.size
        if logicalSize.width > 0 && logicalSize.height > 0 {
            bridge.setHostWindowSize(Int32(logicalSize.width), height: Int32(logicalSize.height))
        }
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()

        // 初回フレームでタイミング初期化
        if emulationStartTime == 0 {
            emulationStartTime = now
            emulatedTime = 0
            frameInterval = 1.0 / bridge.frameRate
        }

        // FPS計測初期化
        if fpsLastTime == 0 {
            fpsLastTime = now
        }

        if bridge.isFullSpeed() {
            // Full Speed: フレームペーシングなしで最大速度実行
            let deadline = now + 0.012 // ~12ms（描画時間を残す）
            var count = 0
            while CACurrentMediaTime() < deadline && count < 100 {
                _ = bridge.runFrame()
                count += 1
            }
            fpsFrameCount += count
            bridge.drawScreen()
            updateTexture()
            statusBarView?.update(bridge: bridge, fps: currentFPS)

            // 通常モード復帰時のキャッチアップ防止
            emulationStartTime = CACurrentMediaTime()
            emulatedTime = 0
        } else {
            let realElapsed = now - emulationStartTime

            // 仮想時間が実時間より遅れている場合のみ VM を実行
            if emulatedTime <= realElapsed {
                let framesExecuted = bridge.runFrame()
                fpsFrameCount += Int(framesExecuted)
                emulatedTime += Double(framesExecuted) * frameInterval

                // Tape fast-load: テープ再生中かつ CMT Signal OFF の間、追加フレームを実行
                var burstCount = 0
                let deadline = now + 0.012
                while bridge.isTapeFastLoadable() && CACurrentMediaTime() < deadline {
                    let extra = bridge.runFrame()
                    fpsFrameCount += Int(extra)
                    burstCount += Int(extra)
                }

                bridge.drawScreen()
                updateTexture()
                statusBarView?.update(bridge: bridge, fps: currentFPS)

                if burstCount > 0 {
                    // バースト後のタイミングリセット（通常モード復帰時のフリーズ防止）
                    emulationStartTime = CACurrentMediaTime()
                    emulatedTime = 0
                } else if realElapsed - emulatedTime > 0.5 {
                    emulatedTime = realElapsed
                }
            }
        }

        // 0.5秒ごとにFPS更新
        let fpsElapsed = now - fpsLastTime
        if fpsElapsed >= 0.5 {
            currentFPS = Double(fpsFrameCount) / fpsElapsed
            fpsFrameCount = 0
            fpsLastTime = now
        }

        // Render
        guard let drawable = currentDrawable,
              let renderPassDescriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let pipelineState = pipelineState,
              let texture = texture else { return }

        encoder.setRenderPipelineState(pipelineState)

        // フルスクリーン時: アスペクト比を維持しつつ最大サイズにスケーリング
        if let window = self.window, window.styleMask.contains(.fullScreen) {
            let drawW = Double(drawable.texture.width)
            let drawH = Double(drawable.texture.height)
            let texW = Double(texture.width)
            let texH = Double(texture.height)

            let scaleX = drawW / texW
            let scaleY = drawH / texH
            let scale = min(scaleX, scaleY)

            let vpW = texW * scale
            let vpH = texH * scale

            let viewport = MTLViewport(
                originX: (drawW - vpW) / 2,
                originY: (drawH - vpH) / 2,
                width: vpW, height: vpH,
                znear: 0, zfar: 1
            )
            encoder.setViewport(viewport)
        }

        encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        encoder.setFragmentTexture(texture, index: 0)
        let sourceHeight = CGFloat(bridge.vmWindowHeight())
        let texHeight = CGFloat(texture.height)
        let needsLinear = sourceHeight != texHeight
        let sampler = needsLinear ? linearSamplerState : nearestSamplerState
        if let sampler = sampler {
            encoder.setFragmentSamplerState(sampler, index: 0)
        }

        // Update shader params
        if let paramsBuffer = paramsBuffer {
            let params = paramsBuffer.contents().bindMemory(to: DisplayParams.self, capacity: 1)
            params.pointee.scanlineEnabled = bridge.isScanlineEnabled() ? 1 : 0
            params.pointee.sourceHeight = UInt32(bridge.vmWindowHeight())
            params.pointee.backingScale = Float(self.window?.backingScaleFactor ?? 1.0)
            params.pointee.filterType = UInt32(bridge.filterType())
            params.pointee.textureWidth = Float(texture.width)
            params.pointee.textureHeight = Float(texture.height)
            encoder.setFragmentBuffer(paramsBuffer, offset: 0, index: 0)
        }
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    // MARK: - Screenshot

    func saveScreenshot(to url: URL) -> Bool {
        // エミュレータの画面バッファから直接画像を作成
        guard let buffer = bridge.screenBuffer() else {
            NSLog("Screenshot: failed to get screen buffer")
            return false
        }

        let width = Int(bridge.screenWidth)
        let height = Int(bridge.screenHeight)

        guard width > 0 && height > 0 else {
            NSLog("Screenshot: invalid dimensions: \(width)x\(height)")
            return false
        }

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bufferSize = height * bytesPerRow

        // バッファからデータをコピーし、Alpha を 0xFF に設定
        var pixelData = [UInt8](repeating: 0, count: bufferSize)
        memcpy(&pixelData, buffer, bufferSize)
        for i in stride(from: 3, to: bufferSize, by: 4) {
            pixelData[i] = 0xFF  // BGRA の A を 0xFF に
        }

        guard let dataProvider = CGDataProvider(data: Data(pixelData) as CFData) else {
            return false
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // BGRA8: byteOrder32Little + noneSkipFirst（Alpha チャネルを無視）
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            NSLog("Screenshot: failed to create CGImage")
            return false
        }

        // CGImageDestination で直接 PNG ファイルを書き出し
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
        ) else {
            NSLog("Screenshot: failed to create image destination")
            return false
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        if CGImageDestinationFinalize(destination) {
            NSLog("Screenshot saved: \(width)x\(height) -> \(url.path)")
            return true
        } else {
            NSLog("Screenshot: failed to finalize PNG")
            return false
        }
    }
}

