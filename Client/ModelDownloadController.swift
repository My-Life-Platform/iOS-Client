import UIKit
import PinLayout
import Combine

final class ModelDownloadController: UIViewController {

    private var cancellables = Set<AnyCancellable>()

    private let infoView = InfoView(frame: .zero)

    private let progressView = UIProgressView(frame: .zero)

    private let downloadButton = UIButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground

        self.view.addSubview(self.infoView)
        self.view.addSubview(self.progressView)
        self.view.addSubview(self.downloadButton)

        self.setUpInfoView()
        self.setUpProgressView()
        self.setUpDownloadButton()

        LLMManager.shared.isModelInstalledPublisher
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] isModelInstalled in
                if isModelInstalled {
                    self?.dismiss(animated: true)
                }
            }
            .store(in: &self.cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let baseMargin: CGFloat = 20

        self.infoView.pin
            .all()

        self.downloadButton.pin
            .horizontally(baseMargin)
            .bottom(self.view.pin.safeArea.bottom)
            .height(54)

        self.progressView.pin
            .above(of: self.downloadButton)
            .marginBottom(baseMargin)
            .horizontally(baseMargin)
    }

    private func setUpInfoView() {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 64, weight: .semibold).rounded())
        self.infoView.image = UIImage(systemName: "arrow.down.circle.dotted")?.applyingSymbolConfiguration(configuration)
        self.infoView.title = "Install a model"
        self.infoView.subtitle = "In order to use MiniApp's you have to install a model\nDon't close this screen while downloading"
    }

    private func setUpProgressView() {
        LLMManager.shared.downloadProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.setProgress(progress, animated: true)
            }
            .store(in: &self.cancellables)
    }

    private func setUpDownloadButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        configuration.cornerStyle = .large
        configuration.imagePadding = 6

        self.downloadButton.configuration = configuration

        self.updateButton(isDownloading: false)
        self.downloadButton.addTarget(self, action: #selector(buttonDidTapped(_:)), for: .touchUpInside)
    }

    @objc
    private func buttonDidTapped(_ button: UIButton) {
        self.updateButton(isDownloading: true)

        Task {
            do {
                try await LLMManager.shared.loadModel()

                DispatchQueue.main.async {
                    self.updateButton(isDownloading: false)
                    self.downloadButton.isEnabled = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.updateButton(isDownloading: false)

                    self.showAlert(title: "Error downloading model", message: error.localizedDescription)
                }
            }
        }
    }

    private func updateButton(isDownloading: Bool) {
        let text = isDownloading ? "Downloading Llama 3.2 3b" : "Download Llama 3.2 3b"

        self.downloadButton.configuration?.attributedTitle = AttributedString(text, attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .kern: -0.4,
            .foregroundColor: UIColor.white
        ]))

        self.downloadButton.isEnabled = !isDownloading
        self.downloadButton.configuration?.showsActivityIndicator = isDownloading
    }

}
