import UIKit
import PinLayout
import Combine

class RootViewController: UIViewController, UITextFieldDelegate {

    private var cancellables = Set<AnyCancellable>()

    private var keyboardHeight: CGFloat?

    private let tapGestureRecognizer = UITapGestureRecognizer()

    private let linkTextField = UITextField(frame: .zero)

    private let modelDownloadedButton = UIButton(frame: .zero)

    private let continueButton = UIButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.systemBackground

        self.view.addSubview(self.linkTextField)
        self.view.addSubview(self.modelDownloadedButton)
        self.view.addSubview(self.continueButton)
        self.view.addGestureRecognizer(self.tapGestureRecognizer)

        self.setUpLinkTextField()
        self.setUpModelDownloadedButton()
        self.setUpContinueButton()
        self.setUpTapGestureRecognizer()

        self.observeKeyboard()
        self.updateContinueButton(with: self.linkTextField.text?.isEmpty == false, animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let baseMargin: CGFloat = 20

        self.linkTextField.pin
            .horizontally(baseMargin)
            .vCenter(-baseMargin * 4)
            .height(54)

        self.modelDownloadedButton.pin
            .below(of: self.linkTextField, aligned: .center)
            .marginTop(16)
            .sizeToFit()

        if let keyboardHeight {
            self.continueButton.pin
                .bottom(keyboardHeight + baseMargin)
                .start(baseMargin)
                .end(baseMargin)
                .height(54)
        } else {
            self.continueButton.pin
                .bottom(self.view.pin.safeArea.bottom + baseMargin)
                .start(baseMargin)
                .end(baseMargin)
                .height(54)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.view.endEditing(true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.didEnter()

        return false
    }

    private func setUpLinkTextField() {
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .kern: -0.4,
            .foregroundColor: UIColor.quaternaryLabel
        ]

        self.linkTextField.attributedPlaceholder = NSAttributedString(string: "Link to MiniApp",
                                                                      attributes: placeholderAttributes)

        let typingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .kern: -0.4,
            .foregroundColor: UIColor.label
        ]

        self.linkTextField.autocorrectionType = .no
        self.linkTextField.autocapitalizationType = .none
        self.linkTextField.typingAttributes = typingAttributes
        self.linkTextField.backgroundColor = UIColor.systemGray6
        self.linkTextField.layer.cornerRadius = 14
        self.linkTextField.leftViewMode = .always
        self.linkTextField.delegate = self
        self.linkTextField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)

        let container = UIView(
            frame: CGRect(
                origin: CGPoint(x: 0, y: 16),
                size: CGSize(width: 36, height: 22)
            )
        )

        let label = UILabel(
            frame: CGRect(
                origin: CGPoint(x: 10, y: 0),
                size: CGSize(width: 24, height: 22)
            )
        )

        let textAttachment = NSTextAttachment(image: UIImage(systemName: "link")!)
        let attributedText = NSMutableAttributedString()
        attributedText.append(NSAttributedString(attachment: textAttachment))
        attributedText.addAttributes(typingAttributes, range: NSRange(location: 0, length: attributedText.length))

        label.attributedText = attributedText

        container.addSubview(label)

        self.linkTextField.leftView = container
        self.linkTextField.text = "https://chatty-telegram-bot.lovable.app/"
    }

    private func setUpModelDownloadedButton() {
        let update: (_ isModelInstalled: Bool) -> Void = { [weak self] isModelInstalled in
            guard let self, var config = self.modelDownloadedButton.configuration else {
                return
            }

            let text = isModelInstalled ? "Model is installed" : "Model is not installed"

            config.attributedTitle = AttributedString(text, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
                .kern: -0.4,
                .foregroundColor: UIColor.white
            ]))

            let color = isModelInstalled ? UIColor.systemGreen : UIColor.systemRed
            config.baseForegroundColor = color
            config.baseBackgroundColor = color

            let image = isModelInstalled ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "xmark.circle.fill")
            config.image = image
            config.imagePadding = 6

            self.modelDownloadedButton.configuration = config
        }

        var configuration = UIButton.Configuration.tinted()
        configuration.buttonSize = .large
        configuration.cornerStyle = .large

        self.modelDownloadedButton.configuration = configuration
        self.modelDownloadedButton.addTarget(self, action: #selector(self.modelDownloadButtonDidTapped(_:)), for: .touchUpInside)

        LLMManager.shared.isModelInstalledPublisher
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { isModelInstalled in
                update(isModelInstalled)
            }
            .store(in: &self.cancellables)

        update(LLMManager.shared.isModelInstalled)
    }

    private func setUpContinueButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        configuration.cornerStyle = .large
        configuration.attributedTitle = AttributedString("Open MiniApp", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .kern: -0.4,
            .foregroundColor: UIColor.white
        ]))

        self.continueButton.configuration = configuration
        self.continueButton.addTarget(self, action: #selector(self.continueButtonDidTapped(_:)), for: .touchUpInside)

        self.updateContinueButton(with: false, animated: true)
    }

    private func setUpTapGestureRecognizer() {
        self.tapGestureRecognizer.addTarget(self, action: #selector(self.tapGestureRecognizerDidTriggered(_:)))
    }

    private func observeKeyboard() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                      let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                let animationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                    return
                }

                self.keyboardHeight = keyboardSize.height

                UIView.animate(withDuration: animationDuration) {
                    self.continueButton.pin
                        .bottom(keyboardSize.height + 20)
                }
            }
            .store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self,
                let animationDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                    return
                }

                self.keyboardHeight = nil

                UIView.animate(withDuration: animationDuration) {
                    self.continueButton.pin
                        .bottom(self.view.pin.safeArea.bottom + 20)
                }
            }
            .store(in: &self.cancellables)
    }

    private func updateContinueButton(with isEnabled: Bool, animated: Bool) {
        let performChanges: () -> Void = {
            self.continueButton.isEnabled = isEnabled
        }

        guard animated else {
            performChanges()
            return
        }

        UIView.animate(withDuration: CATransaction.animationDuration()) {
            performChanges()
        }
    }

    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        let isEnabled = textField.text?.isEmpty == false
        self.updateContinueButton(with: isEnabled, animated: true)
    }

    @objc
    private func continueButtonDidTapped(_ button: UIButton) {
        self.didEnter()
    }

    @objc
    private func modelDownloadButtonDidTapped(_ button: UIButton) {
        guard !LLMManager.shared.isModelInstalled else {
            self.showAlert(title: "Model already installed")

            return
        }

        self.present(ModelDownloadController(), animated: true)
    }

    @objc
    private func tapGestureRecognizerDidTriggered(_ tapGestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    private func didEnter() {
        guard let value = self.linkTextField.text else {
            return
        }

        self.view.endEditing(true)

        guard value.isValidURL, let url = URL(string: value) else {
            self.showAlert(title: "Error", message: "Invalid url")

            return
        }

        let miniAppController = MiniAppController(url: url)
        self.present(miniAppController, animated: true)
    }

}

