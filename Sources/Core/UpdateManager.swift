import Foundation
import AppKit

class UpdateManager: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion = ""
    @Published var isChecking = false
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var errorMessage: String?

    private let repoOwner = "Sakura-cool"
    private let repoName = "SoundFlow"
    private let checkInterval: TimeInterval = 3600

    private var checkTimer: Timer?

    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    func startAutoCheck() {
        checkForUpdate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkForUpdate()
        }
    }

    func stopAutoCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    func checkForUpdate() {
        guard !isChecking else { return }
        isChecking = true
        errorMessage = nil

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            isChecking = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isChecking = false

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self?.errorMessage = "Failed to check for updates"
                    return
                }

                let remoteVersion = tagName.replacingOccurrences(of: "v", with: "")
                self?.latestVersion = remoteVersion

                if self?.isNewerVersion(remoteVersion, than: self?.currentVersion ?? "0.0.0") == true {
                    self?.updateAvailable = true
                }
            }
        }
        task.resume()
    }

    func downloadAndInstall() {
        guard !isDownloading else { return }
        isDownloading = true
        errorMessage = nil
        downloadProgress = 0

        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest"
        guard let url = URL(string: urlString) else {
            isDownloading = false
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let assets = json["assets"] as? [[String: Any]] else {
                DispatchQueue.main.async {
                    self?.isDownloading = false
                    self?.errorMessage = "Failed to fetch release info"
                }
                return
            }

            guard let asset = assets.first,
                  let assetUrlString = asset["browser_download_url"] as? String,
                  let assetUrl = URL(string: assetUrlString) else {
                DispatchQueue.main.async {
                    self?.isDownloading = false
                    self?.errorMessage = "No download found"
                }
                return
            }

            self?.performDownload(from: assetUrl)
        }
        task.resume()
    }

    private func performDownload(from url: URL) {
        let task = URLSession.shared.downloadTask(with: url) { [weak self] tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self?.isDownloading = false
                    self?.errorMessage = "Download failed"
                }
                return
            }

            DispatchQueue.main.async {
                self?.downloadProgress = 1.0
                self?.installUpdate(from: tempURL)
            }
        }

        let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.downloadProgress = progress.fractionCompleted
            }
        }
        task.resume()

        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            observation.invalidate()
        }
    }

    private func installUpdate(from tempURL: URL) {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let tempDir = appSupport.appendingPathComponent("SoundFlowUpdate")
            try? FileManager.default.removeItem(at: tempDir)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let zipPath = tempDir.appendingPathComponent("update.zip")
            try FileManager.default.moveItem(at: tempURL, to: zipPath)

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
            process.arguments = ["-o", zipPath.path, "-d", tempDir.path]
            try process.run()
            process.waitUntilExit()

            guard process.terminationStatus == 0 else {
                isDownloading = false
                errorMessage = "Failed to extract update"
                return
            }

            let contents = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
            guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
                isDownloading = false
                errorMessage = "No .app found in update"
                return
            }

            let currentAppPath = Bundle.main.bundleURL
            let backupPath = currentAppPath.deletingLastPathComponent()
                .appendingPathComponent("SoundFlow_backup.app")

            try? FileManager.default.removeItem(at: backupPath)
            try FileManager.default.moveItem(at: currentAppPath, to: backupPath)
            try FileManager.default.copyItem(at: appBundle, to: currentAppPath)

            try? FileManager.default.removeItem(at: tempDir)

            DispatchQueue.main.async {
                self.isDownloading = false
                self.updateAvailable = false

                let alert = NSAlert()
                alert.messageText = "Update Installed"
                alert.informativeText = "SoundFlow v\(self.latestVersion) has been installed. Restart to apply changes."
                alert.addButton(withTitle: "Restart")
                alert.addButton(withTitle: "Later")
                alert.alertStyle = .informational

                if alert.runModal() == .alertFirstButtonReturn {
                    let path = currentAppPath.path
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-n", path]
                    try? process.run()
                    NSApplication.shared.terminate(nil)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.isDownloading = false
                self.errorMessage = "Install failed: \(error.localizedDescription)"
            }
        }
    }

    private func isNewerVersion(_ remote: String, than local: String) -> Bool {
        let remoteParts = remote.split(separator: ".").compactMap { Int($0) }
        let localParts = local.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(remoteParts.count, localParts.count) {
            let r = i < remoteParts.count ? remoteParts[i] : 0
            let l = i < localParts.count ? localParts[i] : 0
            if r > l { return true }
            if r < l { return false }
        }
        return false
    }
}
