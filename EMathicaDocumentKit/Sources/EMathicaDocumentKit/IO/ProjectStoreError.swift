import Foundation

public enum ProjectStoreError: Error {
    case projectNotFound(UUID)
    case invalidPackage(URL)
    case encodingFailed(String)
    case decodingFailed(String)
    case ioFailed(String)
    case unsupportedVersion(String)
}
