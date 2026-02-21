//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Nodira Tillayeva on 2026/02/21.
//

import UIKit

class ShareViewController: UIViewController {
    private let appGroupId = "group.com.example.steplynara.shared"
    private let sharedKey = "ShareKey"
    private var didComplete = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        handleSharedContent()
    }

    private func handleSharedContent() {
        // Safety timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.done()
        }

        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            done()
            return
        }

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Use raw string identifiers to avoid UniformTypeIdentifiers dependency
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let url = item as? URL {
                                self?.saveURL(url.absoluteString)
                            } else if let urlString = item as? String {
                                self?.saveURL(urlString)
                            } else {
                                self?.done()
                            }
                        }
                    }
                    return
                }

                if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                    provider.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] item, _ in
                        DispatchQueue.main.async {
                            if let text = item as? String,
                               text.hasPrefix("http://") || text.hasPrefix("https://") {
                                self?.saveURL(text)
                            } else {
                                self?.done()
                            }
                        }
                    }
                    return
                }
            }
        }

        done()
    }

    private func saveURL(_ urlString: String) {
        // Save to App Group UserDefaults
        if let userDefaults = UserDefaults(suiteName: appGroupId) {
            userDefaults.set(urlString, forKey: sharedKey)
            userDefaults.synchronize()
        }

        // Try to open main app
        if let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "steply://share?url=\(encoded)") {
            extensionContext?.open(url, completionHandler: { [weak self] _ in
                self?.done()
            })
        }

        // Fallback close
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.done()
        }
    }

    private func done() {
        guard !didComplete else { return }
        didComplete = true
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
