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
                return makeFallbackView(identity: identity)
            }

            let view = MTKView(frame: .zero, device: device)
            view.autoresizingMask = [.width, .height]
            view.colorPixelFormat = .bgra8Unorm
            view.framebufferOnly = true
            view.enableSetNeedsDisplay = true
            view.isPaused = true
            view.preferredFramesPerSecond = 30
            view.clearColor = identity.mode.theme.palette.background.metalClearColor

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
                view.layer?.backgroundColor = identity.mode.theme.palette.background.nsColor.cgColor
                return
            }

            metalView.clearColor = identity.mode.theme.palette.background.metalClearColor

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

        private func makeFallbackView(identity: VisualIdentity) -> NSView {
            let view = NSView(frame: .zero)
            view.wantsLayer = true
            view.layer?.backgroundColor = identity.mode.theme.palette.background.nsColor.cgColor
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
        var paletteBackground: SIMD4<Float>
        var primaryAccent: SIMD4<Float>
        var secondaryAccent: SIMD4<Float>
        var statusAccent: SIMD4<Float>
        var gridScale: Float
        var fieldScale: Float
        var scanlineIntensity: Float
        var noiseIntensity: Float
        var detailDensity: Float
        var glowIntensity: Float
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
        let theme = identity.mode.theme
        let motion = theme.motion
        let scaledEventMagnitude = event.magnitude * motion.eventGain
        let magnitude = configuration.pulseMagnitude(for: scaledEventMagnitude)

        guard magnitude > 0 else {
            pulse = 0
            activeUntil = CACurrentMediaTime()
            return magnitude
        }

        pulse = min(1, max(pulse, Float(magnitude)))
        activeUntil = CACurrentMediaTime() + identity.mode.theme.motion.maxPulseDuration
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
        let theme = identity.mode.theme
        pulse = max(0, pulse - delta * Float(identity.mode.theme.motion.pulseDecay))

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
            mode: identity.mode.shaderValue,
            paletteBackground: theme.palette.background.shaderVector,
            primaryAccent: theme.palette.primaryAccent.shaderVector,
            secondaryAccent: theme.palette.secondaryAccent.shaderVector,
            statusAccent: theme.palette.statusAccent.shaderVector,
            gridScale: Float(max(0.1, theme.shader.lineIntensity * (0.75 + theme.motion.detailDensity))),
            fieldScale: Float(theme.shader.fieldScale),
            scanlineIntensity: Float(theme.shader.lineIntensity),
            noiseIntensity: Float(theme.shader.grainIntensity),
            detailDensity: Float(theme.motion.detailDensity),
            glowIntensity: Float(theme.shader.glowIntensity)
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
        float4 paletteBackground;
        float4 primaryAccent;
        float4 secondaryAccent;
        float4 statusAccent;
        float gridScale;
        float fieldScale;
        float scanlineIntensity;
        float noiseIntensity;
        float detailDensity;
        float glowIntensity;
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

        float detail = clamp(uniforms.detailDensity, 0.05, 1.0);
        float drift = uniforms.time * mix(0.035, 0.20, detail);
        float fieldScale = max(uniforms.fieldScale, 0.05);
        float waveA = sin((centered.x + uniforms.seed.x) * 16.0 * fieldScale + drift * 5.0);
        float waveB = cos((centered.y + uniforms.seed.y) * 18.0 * fieldScale - drift * 4.0);
        float field = smoothstep(-0.8, 1.0, waveA * 0.45 + waveB * 0.38 - radius * 0.92);

        float lineScaleX = mix(34.0, 96.0, detail) * max(uniforms.gridScale, 0.08);
        float lineScaleY = mix(28.0, 78.0, detail) * max(uniforms.gridScale, 0.08);
        float gridX = smoothstep(0.985, 1.0, cos((uv.x + uniforms.seed.x * 0.03) * lineScaleX));
        float gridY = smoothstep(0.988, 1.0, cos((uv.y + uniforms.seed.y * 0.03) * lineScaleY));
        float scan = smoothstep(
            0.998,
            1.0,
            sin(uv.y * mix(120.0, 260.0, detail) + uniforms.time * (0.35 + uniforms.scanlineIntensity))
        ) * uniforms.scanlineIntensity;

        float pulse = clamp(uniforms.pulse, 0.0, 1.0);
        float vignette = smoothstep(0.86, 0.18, radius);

        float3 base = uniforms.paletteBackground.rgb;
        float3 primary = uniforms.primaryAccent.rgb;
        float3 secondary = uniforms.secondaryAccent.rgb;
        float3 status = uniforms.statusAccent.rgb;
        float glow = uniforms.glowIntensity;
        float line = uniforms.scanlineIntensity;
        float grain = uniforms.noiseIntensity;

        float3 color = base;
        if (uniforms.mode < 0.5) {
            float tronSeed = uniforms.seed.x * 31.0 + uniforms.seed.y * 17.0;
            float circuit = smoothstep(
                0.992,
                1.0,
                cos((uv.x + uv.y * 0.35 + tronSeed * 0.01) * lineScaleX * 0.72 + drift * 2.0)
            );
            color += primary * field * (0.12 + pulse * 0.20) * glow;
            color += secondary * vignette * 0.18;
            color += status * circuit * (0.014 + pulse * 0.032) * line;
            color += primary * (gridX + gridY + scan) * (0.018 + pulse * 0.045) * line;
        } else if (uniforms.mode >= 0.5 && uniforms.mode < 1.5) {
            float severanceSeed = uniforms.seed.y * 0.04 - uniforms.seed.x * 0.025;
            float panel = smoothstep(0.46, 0.468, abs(centered.x + severanceSeed)) * 0.45
                + smoothstep(0.28, 0.288, abs(centered.y - severanceSeed)) * 0.45;
            float fluorescent = smoothstep(0.994, 1.0, cos((uv.y + severanceSeed) * 54.0));
            float lowPulse = pulse * 0.16;
            color += primary * field * (0.020 + lowPulse * 0.020) * glow;
            color += secondary * panel * 0.045;
            color += status * fluorescent * (0.004 + lowPulse * 0.006) * line;
        } else if (uniforms.mode >= 2.5 && uniforms.mode < 3.5) {
            float rain = smoothstep(
                0.985,
                1.0,
                cos((uv.y * 190.0 + uniforms.seed.x * 13.0) + sin(uv.x * 42.0) * 2.5 + drift * 9.0)
            );
            float glyph = smoothstep(
                0.992,
                1.0,
                cos((floor(uv.x * 54.0) + floor(uv.y * 38.0) + uniforms.seed.y * 19.0) * 1.618)
            );
            color += primary * (rain + glyph) * (0.020 + pulse * 0.046) * line;
            color += secondary * field * (0.09 + pulse * 0.05) * glow;
            color += status * scan * (0.012 + pulse * 0.026) * line;
        } else if (uniforms.mode >= 3.5 && uniforms.mode < 4.5) {
            float barrel = smoothstep(0.88, 0.08, radius) * 0.18;
            float phosphor = smoothstep(0.965, 1.0, sin(uv.y * 420.0 + uniforms.seed.y * 5.0));
            float trace = smoothstep(0.992, 1.0, cos((uv.x + uniforms.seed.x * 0.04) * lineScaleX * 0.42));
            color += primary * (field + trace + phosphor) * (0.026 + pulse * 0.035) * glow;
            color += secondary * vignette * (0.14 + barrel);
            color += status * scan * (0.008 + pulse * 0.018) * line;
        } else if (uniforms.mode >= 4.5 && uniforms.mode < 5.5) {
            float breachSeed = uniforms.seed.x * 0.08 - uniforms.seed.y * 0.04;
            float diagonal = smoothstep(0.988, 1.0, cos((uv.x * 1.2 + uv.y * 0.8 + breachSeed) * lineScaleX * 0.62 + drift * 3.0));
            float lock = smoothstep(0.976, 1.0, cos((abs(centered.x) + abs(centered.y)) * 42.0 - drift * 2.0));
            color += primary * (diagonal + gridX) * (0.020 + pulse * 0.055) * line;
            color += secondary * field * (0.11 + pulse * 0.08) * glow;
            color += status * lock * (0.008 + pulse * 0.025);
        } else {
            float appleSeed = uniforms.seed.x * 0.07 + uniforms.seed.y * 0.11;
            float aura = smoothstep(0.78, 0.12, radius + appleSeed * 0.018);
            float depth = smoothstep(-0.25, 0.85, field + sin((centered.x + appleSeed) * 4.0 + drift) * 0.08);
            color += primary * aura * (0.060 + pulse * 0.050) * glow;
            color += secondary * depth * 0.060;
            color += status * scan * (0.006 + pulse * 0.014) * line;
        }

        float micro = fract(sin(dot(uv + uniforms.seed, float2(12.9898, 78.233))) * 43758.5453);
        color += (micro - 0.5) * grain * 0.014;

        return float4(color, 1.0);
    }
    """
}

private extension VisualColor {
    var nsColor: NSColor {
        NSColor(
            calibratedRed: red,
            green: green,
            blue: blue,
            alpha: alpha
        )
    }

    var metalClearColor: MTLClearColor {
        MTLClearColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var shaderVector: SIMD4<Float> {
        SIMD4<Float>(
            Float(red),
            Float(green),
            Float(blue),
            Float(alpha)
        )
    }
}
