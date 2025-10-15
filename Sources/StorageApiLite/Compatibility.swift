import Foundation

#if os(Linux)
import FoundationNetworking
#endif

// MARK: - Cross-platform HTTP header access
extension HTTPURLResponse {
    /// Cross-platform wrapper for accessing HTTP header values
    func value(forHTTPHeaderField field: String) -> String? {
        return allHeaderFields[field] as? String
    }
}
