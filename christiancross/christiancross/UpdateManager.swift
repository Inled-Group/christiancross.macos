
import Foundation
import Cocoa

class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    private let currentVersion = "1.1.0" // Update this with each release
    private let repoURL = "https://api.github.com/repos/Inled-Group/christiancross.macos/releases/latest"
    
    struct GitHubRelease: Codable {
        let tagName: String
        let name: String
        let body: String
        let htmlUrl: String
        let assets: [Asset]
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name, body
            case htmlUrl = "html_url"
            case assets
        }
        
        struct Asset: Codable {
            let name: String
            let browserDownloadUrl: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
            }
        }
    }
    
    private init() {}
    
    func checkForUpdates(completion: @escaping (Bool, GitHubRelease?) -> Void) {
        guard let url = URL(string: repoURL) else {
            completion(false, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil else {
                completion(false, nil)
                return
            }
            
            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let hasUpdate = self.isNewerVersion(release.tagName, than: self.currentVersion)
                completion(hasUpdate, hasUpdate ? release : nil)
            } catch {
                print("Error decoding release data: \(error)")
                completion(false, nil)
            }
        }
        
        task.resume()
    }
    
    private func isNewerVersion(_ newVersion: String, than currentVersion: String) -> Bool {
        let newComponents = newVersion.replacingOccurrences(of: "v", with: "").components(separatedBy: ".")
        let currentComponents = currentVersion.components(separatedBy: ".")
        
        let maxCount = max(newComponents.count, currentComponents.count)
        
        for i in 0..<maxCount {
            let newPart = i < newComponents.count ? Int(newComponents[i]) ?? 0 : 0
            let currentPart = i < currentComponents.count ? Int(currentComponents[i]) ?? 0 : 0
            
            if newPart > currentPart {
                return true
            } else if newPart < currentPart {
                return false
            }
        }
        
        return false
    }
    
    func showUpdateAlert(for release: GitHubRelease) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "New update available"
            alert.informativeText = """
            Version \(release.tagName) available

            \(release.body.isEmpty ? "A new version of Cruz Cristiana is available." : release.body)
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Download")
            alert.addButton(withTitle: "Remind me later")
            alert.addButton(withTitle: "Skip this version")
            
            let response = alert.runModal()
            
            switch response {
            case .alertFirstButtonReturn: // Download
                self.openDownloadPage(release.htmlUrl)
            case .alertSecondButtonReturn: // Remind me later
                break
            case .alertThirdButtonReturn: // Skip this version
                self.markVersionAsSkipped(release.tagName)
            default:
                break
            }
        }
    }
    
    private func openDownloadPage(_ urlString: String) {
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func markVersionAsSkipped(_ version: String) {
        UserDefaults.standard.set(version, forKey: "SkippedVersion")
    }
    
    private func isVersionSkipped(_ version: String) -> Bool {
        return UserDefaults.standard.string(forKey: "SkippedVersion") == version
    }
    
    func checkForUpdatesWithUserPreferences() {
        checkForUpdates { [weak self] hasUpdate, release in
            guard let self = self,
                  hasUpdate,
                  let release = release,
                  !self.isVersionSkipped(release.tagName) else {
                return
            }
            self.showUpdateAlert(for: release)
        }
    }
}
