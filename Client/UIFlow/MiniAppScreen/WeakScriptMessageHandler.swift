import WebKit

class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {

    private let handler: (WKScriptMessage) -> ()

    init(_ handler: @escaping (WKScriptMessage) -> ()) {
        self.handler = handler

        super.init()
    }

    func userContentController(_ controller: WKUserContentController, didReceive scriptMessage: WKScriptMessage) {
        self.handler(scriptMessage)
    }
    
}
