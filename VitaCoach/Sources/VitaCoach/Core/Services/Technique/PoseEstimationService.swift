import Foundation
import CoreGraphics
#if canImport(Vision)
import Vision
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Один кадр позы: нормализованные координаты ключевых суставов (0...1).
struct PoseFrame: Hashable {
    var time: Double
    /// Ключи: shoulder, hip, knee, ankle, elbow, wrist.
    var points: [String: CGPoint]

    func point(_ name: String) -> CGPoint? { points[name] }
}

/// Оценка позы человека по видео через Vision (`VNDetectHumanBodyPoseRequest`).
/// Деградирует до пустого результата там, где Vision недоступен.
@MainActor
final class PoseEstimationService {

    enum PoseError: LocalizedError {
        case unsupported
        case noFrames
        var errorDescription: String? {
            switch self {
            case .unsupported: return "Анализ позы недоступен на этом устройстве."
            case .noFrames: return "Не удалось распознать движения на видео."
            }
        }
    }

    /// Извлекает позы из видео, сэмплируя примерно `fps` кадров в секунду.
    func analyzeVideo(url: URL, fps: Double = 6) async throws -> [PoseFrame] {
        #if canImport(Vision) && canImport(AVFoundation)
        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration).seconds) ?? 0
        guard duration > 0 else { throw PoseError.noFrames }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = CMTime(value: 1, timescale: 10)

        let step = 1.0 / fps
        var times: [CMTime] = []
        var t = 0.0
        while t < duration {
            times.append(CMTime(seconds: t, preferredTimescale: 600))
            t += step
        }

        var frames: [PoseFrame] = []
        for time in times {
            guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { continue }
            if let frame = detectPose(in: cgImage, time: time.seconds) {
                frames.append(frame)
            }
        }
        guard !frames.isEmpty else { throw PoseError.noFrames }
        return frames
        #else
        throw PoseError.unsupported
        #endif
    }

    #if canImport(Vision)
    private func detectPose(in cgImage: CGImage, time: Double) -> PoseFrame? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
        try? handler.perform([request])
        guard let observation = request.results?.first else { return nil }
        guard let recognized = try? observation.recognizedPoints(.all) else { return nil }

        func best(_ left: VNHumanBodyPoseObservation.JointName,
                  _ right: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
            let l = recognized[left]
            let r = recognized[right]
            let lc = l?.confidence ?? 0
            let rc = r?.confidence ?? 0
            let minConfidence: Float = 0.1
            if lc >= rc, lc > minConfidence, let l { return l.location }
            if rc > minConfidence, let r { return r.location }
            return nil
        }

        var points: [String: CGPoint] = [:]
        points["shoulder"] = best(.leftShoulder, .rightShoulder)
        points["hip"] = best(.leftHip, .rightHip)
        points["knee"] = best(.leftKnee, .rightKnee)
        points["ankle"] = best(.leftAnkle, .rightAnkle)
        points["elbow"] = best(.leftElbow, .rightElbow)
        points["wrist"] = best(.leftWrist, .rightWrist)

        let cleaned = points.compactMapValues { $0 }
        return cleaned.count >= 3 ? PoseFrame(time: time, points: cleaned) : nil
    }
    #endif

    /// Угол в точке `b`, образованный отрезками b→a и b→c, в градусах (0...180).
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let v1 = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let v2 = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let mag1 = (v1.dx * v1.dx + v1.dy * v1.dy).squareRoot()
        let mag2 = (v2.dx * v2.dx + v2.dy * v2.dy).squareRoot()
        guard mag1 > 0, mag2 > 0 else { return 0 }
        let cosine = max(-1, min(1, dot / (mag1 * mag2)))
        return acos(cosine) * 180 / .pi
    }

    /// Отклонение отрезка a→b от вертикали, в градусах (0 = строго вертикально).
    static func verticalDeviation(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = abs(b.x - a.x)
        let dy = abs(b.y - a.y)
        guard dy > 0 else { return 90 }
        return atan(dx / dy) * 180 / .pi
    }
}
