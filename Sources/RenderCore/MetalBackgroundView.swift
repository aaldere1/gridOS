import AppKit
import Metal
import MetalKit
import simd
import SwiftUI

public struct MetalBackgroundView: NSViewRepresentable {
    private let identity: VisualIdentity
    private let event: RenderEvent?
    private let effectConfiguration: VisualEffectConfiguration

    public init(
        identity: VisualIdentity = .default,
        event: RenderEvent? = nil,
        effectConfiguration: VisualEffectConfiguration = .defaultValue
    ) {
        self.identity = identity
        self.event = event
        self.effectConfiguration = effectConfiguration
    }

    @MainActor public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor public func makeNSView(context: Context) -> NSView {
        context.coordinator.makeView(
            identity: identity,
            event: event,
            effectConfiguration: effectConfiguration
        )
    }

    @MainActor public func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(
            nsView,
            identity: identity,
            event: event,
            effectConfiguration: effectConfiguration
        )
    }

    @MainActor public static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.shutdown()
    }

    @MainActor public final class Coordinator {
        private let renderer = MetalBackgroundRenderer()
        private weak var metalView: MTKView?
        private var animationTimer: Timer?
        private var lastEventSequence: UInt64?

        func makeView(
            identity: VisualIdentity,
            event: RenderEvent?,
            effectConfiguration: VisualEffectConfiguration
        ) -> NSView {
            guard let device = MTLCreateSystemDefaultDevice() else {
                return makeFallbackView()
            }

            let view = MTKView(frame: .zero, device: device)
            view.autoresizingMask = [.width, .height]
            view.colorPixelFormat = .bgra8Unorm
            view.framebufferOnly = true
            view.enableSetNeedsDisplay = true
            view.isPaused = true
            view.preferredFramesPerSecond = 30
            view.clearColor = MTLClearColor(red: 0.006, green: 0.008, blue: 0.012, alpha: 1)

            renderer.configure(view: view)
            renderer.update(identity: identity)
            view.delegate = renderer
            metalView = view

            if let event {
                submit(event, configuration: effectConfiguration)
            } else {
                view.draw()
            }

            return view
        }

        func update(
            _ view: NSView,
            identity: VisualIdentity,
            event: RenderEvent?,
            effectConfiguration: VisualEffectConfiguration
        ) {
            renderer.update(identity: identity)

            guard let metalView = view as? MTKView else {
                view.layer?.backgroundColor = NSColor(calibratedRed: 0.006, green: 0.008, blue: 0.012, alpha: 1).cgColor
                return
            }

            if let event, event.sequence != lastEventSequence {
                submit(event, configuration: effectConfiguration)
            } else if animationTimer == nil {
                metalView.draw()
            }
        }

        func shutdown() {
            animationTimer?.invalidate()
            animationTimer = nil
            metalView?.delegate = nil
        }

        private func submit(_ event: RenderEvent, configuration: VisualEffectConfiguration) {
            lastEventSequence = event.sequence
            let pulseMagnitude = renderer.record(event: event, configuration: configuration)

            guard pulseMagnitude > 0 else {
                stopAnimation()
                metalView?.draw()
                return
            }

            startAnimationIfNeeded()
        }

        private func startAnimationIfNeeded() {
            guard animationTimer == nil else {
                return
            }

            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.tick()
                }
            }
        }

        private func tick() {
            guard let metalView else {
                stopAnimation()
                return
            }

            metalView.draw()

            guard renderer.shouldContinueAnimating() else {
                stopAnimation()
                return
            }
        }

        private func stopAnimation() {
            animationTimer?.invalidate()
            animationTimer = nil
        }

        private func makeFallbackView() -> NSView {
            let view = NSView(frame: .zero)
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor(calibratedRed: 0.006, green: 0.008, blue: 0.012, alpha: 1).cgColor
            return view
        }
    }
}

final class MetalBackgroundRenderer: NSObject, MTKViewDelegate {
    private struct ShaderUniforms {
        var time: Float
        var pulse: Float
        var seed: SIMD2<Float>
        var resolution: SIMD2<Float>
        var mode: Float
        var padding: SIMD3<Float> = .zero
    }

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var identity = VisualIdentity.default
    private var startTime = CACurrentMediaTime()
    private var lastDrawTime = CACurrentMediaTime()
    private var pulse: Float = 0.22
    private var activeUntil = CACurrentMediaTime()

    @MainActor func configure(view: MTKView) {
        guard let device = view.device else {
            return
        }

        commandQueue = device.makeCommandQueue()

        do {
            let library = try device.makeLibrary(source: Self.shaderSource, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: "gridos_background_vertex")
            descriptor.fragmentFunction = library.makeFunction(name: "gridos_background_fragment")
            descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            pipelineState = nil
        }
    }

    func update(identity: VisualIdentity) {
        self.identity = identity
    }

    @discardableResult
    func record(event: RenderEvent, configuration: VisualEffectConfiguration) -> Double {
        let magnitude = configuration.pulseMagnitude(for: event.magnitude)

        guard magnitude > 0 else {
            pulse = 0
            activeUntil = CACurrentMediaTime()
            return magnitude
        }

        pulse = min(1, max(pulse, Float(magnitude)))
        activeUntil = CACurrentMediaTime() + 1.4
        return magnitude
    }

    func shouldContinueAnimating() -> Bool {
        let now = CACurrentMediaTime()
        return now < activeUntil && pulse > 0.015
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let delta = Float(max(0, min(now - lastDrawTime, 1.0)))
        lastDrawTime = now
        pulse = max(0, pulse - delta * 0.42)

        guard let commandQueue,
              let pipelineState,
              let passDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else {
            return
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: passDescriptor)
        var uniforms = ShaderUniforms(
            time: Float(now - startTime),
            pulse: pulse,
            seed: identity.seed.normalizedVector,
            resolution: SIMD2<Float>(
                max(Float(view.drawableSize.width), 1),
                max(Float(view.drawableSize.height), 1)
            ),
            mode: identity.mode.shaderValue
        )

        encoder?.setRenderPipelineState(pipelineState)
        encoder?.setFragmentBytes(&uniforms, length: MemoryLayout<ShaderUniforms>.stride, index: 0)
        encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }

    static let shaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
        float4 position [[position]];
        float2 uv;
    };

    struct ShaderUniforms {
        float time;
        float pulse;
        float2 seed;
        float2 resolution;
        float mode;
        float3 padding;
    };

    vertex VertexOut gridos_background_vertex(uint vertexID [[vertex_id]]) {
        float2 positions[3] = {
            float2(-1.0, -1.0),
            float2( 3.0, -1.0),
            float2(-1.0,  3.0)
        };

        VertexOut out;
        out.position = float4(positions[vertexID], 0.0, 1.0);
        out.uv = positions[vertexID] * 0.5 + 0.5;
        return out;
    }

    fragment float4 gridos_background_fragment(VertexOut in [[stage_in]],
                                               constant ShaderUniforms &uniforms [[buffer(0)]]) {
        float2 uv = in.uv;
        float aspect = uniforms.resolution.x / max(uniforms.resolution.y, 1.0);
        float2 centered = float2((uv.x - 0.5) * aspect, uv.y - 0.5);
        float radius = length(centered);

        float drift = uniforms.time * 0.18;
        float waveA = sin((centered.x + uniforms.seed.x) * 16.0 + drift * 5.0);
        float waveB = cos((centered.y + uniforms.seed.y) * 18.0 - drift * 4.0);
        float field = smoothstep(-0.8, 1.0, waveA * 0.45 + waveB * 0.38 - radius * 0.92);

        float gridX = smoothstep(0.985, 1.0, cos((uv.x + uniforms.seed.x * 0.03) * 90.0));
        float gridY = smoothstep(0.988, 1.0, cos((uv.y + uniforms.seed.y * 0.03) * 72.0));
        float scan = smoothstep(0.998, 1.0, sin(uv.y * 260.0 + uniforms.time * 0.9));

        float pulse = clamp(uniforms.pulse, 0.0, 1.0);
        float vignette = smoothstep(0.86, 0.18, radius);

        float3 base = float3(0.004, 0.007, 0.011);
        float3 cyan = float3(0.10, 0.72, 0.78);
        float3 blue = float3(0.12, 0.24, 0.46);
        float3 amber = float3(0.95, 0.52, 0.20);

        float3 color = base;
        color += cyan * field * (0.11 + pulse * 0.18);
        color += blue * vignette * 0.16;
        color += amber * (gridX + gridY) * (0.012 + pulse * 0.035);
        color += cyan * scan * (0.018 + pulse * 0.045);

        return float4(color, 1.0);
    }
    """
}
