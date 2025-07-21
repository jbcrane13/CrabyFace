import Foundation

struct PhotoReference: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let url: URL
    let thumbnailUrl: URL
    
    init(id: UUID = UUID(), url: URL, thumbnailUrl: URL) {
        self.id = id
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}