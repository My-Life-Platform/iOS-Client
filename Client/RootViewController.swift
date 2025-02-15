import UIKit
import PinLayout
import Combine

class RootViewController: UIViewController, UITextFieldDelegate {

    private var cancellables = Set<AnyCancellable>()

    private var keyboardHeight: CGFloat?

    private let linkTextField = UITextField(frame: .zero)

    private let continueButton = UIButton(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.systemBackground

        self.view.addSubview(self.linkTextField)
        self.view.addSubview(self.continueButton)

        self.setUpLinkTextField()
        self.setUpContinueButton()

        self.observeKeyboard()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.linkTextField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let baseMargin: CGFloat = 20

        self.linkTextField.pin
            .horizontally(baseMargin)
            .vCenter(-baseMargin)
            .height(54)

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

        self.linkTextField.resignFirstResponder()
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
        self.linkTextField.tintColor = UIColor.systemBackground
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

        let textAttachment = NSTextAttachment(image: UIImage(systemName: "paperclip")!)
        let attributedText = NSMutableAttributedString()
        attributedText.append(NSAttributedString(attachment: textAttachment))
        attributedText.addAttributes(typingAttributes, range: NSRange(location: 0, length: attributedText.length))

        label.attributedText = attributedText

        container.addSubview(label)


        self.linkTextField.leftView = container
    }

    private func setUpContinueButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.buttonSize = .large
        configuration.cornerStyle = .large
        configuration.title = "Open MiniApp"
        configuration.attributedTitle = AttributedString("Open MiniApp", attributes: AttributeContainer([
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .kern: -0.4,
            .foregroundColor: UIColor.white
        ]))

        self.continueButton.configuration = configuration
        self.continueButton.addTarget(self, action: #selector(buttonDidTapped(_:)), for: .touchUpInside)

        self.updateContinueButton(with: false, animated: true)
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
    private func buttonDidTapped(_ button: UIButton) {
        self.didEnter()
    }

    private func didEnter() {
        guard let value = self.linkTextField.text else {
            return
        }

        self.linkTextField.resignFirstResponder()

        guard value.isValidURL, let url = URL(string: value) else {
            self.showError(title: "Invalid url")

            return
        }

        let miniAppController = MiniAppController(url: url)
        self.present(miniAppController, animated: true)
    }

    private func showError(title: String) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default))

        self.present(alertController, animated: true)
    }

}

