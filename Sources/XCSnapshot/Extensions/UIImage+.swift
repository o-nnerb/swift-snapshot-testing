import UIKit

extension UIImage {

    /// Used when the image size has no width or no height to generated the default empty image
    @MainActor
    static var empty: UIImage {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 80))
        label.backgroundColor = .red
        label.text =
        "Error: No image could be generated for this view as its size was zero. Please set an explicit size in the test."
        label.textAlignment = .center
        label.numberOfLines = 3
        return label.asImage()
    }

    func substract(_ image: UIImage, scale: CGFloat?) -> UIImage {
        let width = max(self.size.width, image.size.width)
        let height = max(self.size.height, image.size.height)
        let scale = max(self.scale, image.scale)
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), true, scale)
        image.draw(in: .init(origin: .zero, size: size))
        self.draw(in: .init(origin: .zero, size: size), blendMode: .difference, alpha: 1)
        let differenceImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return differenceImage
    }

    func compare(_ newValue: UIImage, precision: Float, perceptualPrecision: Float) -> String? {
        guard let oldCgImage = self.cgImage else {
            return "Reference image could not be loaded."
        }
        guard let newCgImage = newValue.cgImage else {
            return "Newly-taken snapshot could not be loaded."
        }
        guard newCgImage.width != 0, newCgImage.height != 0 else {
            return "Newly-taken snapshot is empty."
        }
        guard oldCgImage.width == newCgImage.width, oldCgImage.height == newCgImage.height else {
            return "Newly-taken snapshot@\(newValue.size) does not match reference@\(self.size)."
        }
        let pixelCount = oldCgImage.width * oldCgImage.height
        let byteCount = ImageContext.bytesPerPixel * pixelCount
        var oldBytes = [UInt8](repeating: 0, count: byteCount)
        guard let oldData = oldCgImage.context(with: &oldBytes)?.data else {
            return "Reference image's data could not be loaded."
        }
        if let newContext = newCgImage.context(), let newData = newContext.data {
            if memcmp(oldData, newData, byteCount) == 0 { return nil }
        }
        var newerBytes = [UInt8](repeating: 0, count: byteCount)
        guard
            let pngData = newValue.pngData(),
            let newerCgImage = UIImage(data: pngData)?.cgImage,
            let newerContext = newerCgImage.context(with: &newerBytes),
            let newerData = newerContext.data
        else {
            return "Newly-taken snapshot's data could not be loaded."
        }
        if memcmp(oldData, newerData, byteCount) == 0 { return nil }
        if precision >= 1, perceptualPrecision >= 1 {
            return "Newly-taken snapshot does not match reference."
        }
        if perceptualPrecision < 1, #available(iOS 11.0, tvOS 11.0, *) {
            return CIImage(cgImage: oldCgImage).perceptuallyCompare(
                CIImage(cgImage: newCgImage),
                pixelPrecision: precision,
                perceptualPrecision: perceptualPrecision
            )
        } else {
            let byteCountThreshold = Int((1 - precision) * Float(byteCount))
            var differentByteCount = 0
            // NB: We are purposely using a verbose 'while' loop instead of a 'for in' loop.  When the
            //     compiler doesn't have optimizations enabled, like in test targets, a `while` loop is
            //     significantly faster than a `for` loop for iterating through the elements of a memory
            //     buffer. Details can be found in [SR-6983](https://github.com/apple/swift/issues/49531)
            var index = 0
            while index < byteCount {
                defer { index += 1 }
                if oldBytes[index] != newerBytes[index] {
                    differentByteCount += 1
                }
            }
            if differentByteCount > byteCountThreshold {
                let actualPrecision = 1 - Float(differentByteCount) / Float(byteCount)
                return "Actual image precision \(actualPrecision) is less than required \(precision)"
            }
        }
        return nil
    }
}
