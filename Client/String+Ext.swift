import Foundation

extension String {

    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.count)) {
            return match.range.length == self.count
        } else {
            return false
        }
    }

}
