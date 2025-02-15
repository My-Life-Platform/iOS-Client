import UIKit
import WebKit
import PinLayout

final class MiniAppController: UIViewController {

    private static let eventProxySource = "var MyLifeWebViewProxyProto = function() {}; " +
        "MyLifeWebViewProxyProto.prototype.postEvent = function(eventName, eventData) { " +
        "window.webkit.messageHandlers.performAction.postMessage({'eventName': eventName, 'eventData': eventData}); " +
        "}; " +
    "var MyLifeWebViewProxy = new MyLifeWebViewProxyProto();"

    private let webView: WKWebView

    private let url: URL

    init(url: URL) {
        weak var weakSelf: MiniAppController?

        let configuration = WKWebViewConfiguration()

        let contentController = WKUserContentController()
        let eventProxyScript = WKUserScript(source: Self.eventProxySource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(eventProxyScript)

        contentController.add(WeakScriptMessageHandler { message in
            weakSelf?.handleScriptMessage(message)
        }, name: "performAction")

        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .audio

        self.url = url

        self.webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(nibName: nil, bundle: nil)

        weakSelf = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(self.webView)

        self.view.backgroundColor = .systemBackground

        self.webView.load(URLRequest(url: self.url))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.webView.pin
            .all()
    }

    private func setUpWebView() {
        if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }

        self.webView.scrollView.decelerationRate = .normal
        self.webView.scrollView.isScrollEnabled = true
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        self.webView.allowsLinkPreview = false
        self.webView.isOpaque = false
        self.webView.backgroundColor = .systemBackground
    }

    private func handleScriptMessage(_ message: WKScriptMessage) {
        guard let body = message.body as? [String: Any] else {
            return
        }

        guard let eventName = body["eventName"] as? String else {
            return
        }

        let eventData = (body["eventData"] as? String)?.data(using: .utf8)
        let json = try? JSONSerialization.jsonObject(with: eventData ?? Data(), options: []) as? [String: Any]

        switch eventName {
        case "chat_completions":
            guard let json,
                    let prompt = json["message"] as? String,
                    let stringRole = json["role"] as? String,
                    let role = Role(rawValue: stringRole) else {
                return
            }

            let miniAppId = self.url.absoluteString

            let miniAppMessage = Message(role: role, content: prompt, timestamp: Date(), miniAppId: miniAppId)

            Task {
                do {
                    var history = try MiniAppConversationProvider.shared.getHistory(for: self.url.absoluteString)
                    history.append(miniAppMessage)

                    let response = await LLMManager.shared.generate(history: history.map { $0.dictionaryRepresentation() })

                    let newMessages = Message(role: .assistant, content: response, timestamp: Date(), miniAppId: self.url.absoluteString)

                    history.append(newMessages)

                    try MiniAppConversationProvider.shared.saveHistory(for: self.url.absoluteString, messages: history)

                    self.sendEvent(name: "chat_completions_response", data: "{\"response\": \"\(response)\"}")
                } catch {
                    self.sendEvent(name: "chat_completions_response", data: "{\"error\": \"\(error.localizedDescription)\"}")
                }
            }
        default:
            break
        }
    }

    func sendEvent(name: String, data: String?) {
        let script = "window.MyLife.WebView.receiveEvent(\"\(name)\", \(data ?? "null"))"

        self.webView.evaluateJavaScript(script) { _, _ in

        }
    }

}
