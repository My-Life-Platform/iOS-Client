import UIKit
import PinLayout

public final class InfoView: UIView {

    public var image: UIImage? {
        get {
            self.imageView.image
        }

        set {
            self.imageView.image = newValue
        }
    }

    public var title: String? {
        get {
            self.titleLabel.text
        }

        set {
            self.titleLabel.text = newValue
        }
    }

    public var subtitle: String? {
        get {
            self.subtitleLabel.text
        }

        set {
            self.subtitleLabel.text = newValue
        }
    }

    private let containerView = UIView(frame: .zero)

    private let imageView = UIImageView(frame: .zero)

    private let titleLabel = UILabel(frame: .zero)

    private let subtitleLabel = UILabel(frame: .zero)

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.containerView)
        self.containerView.addSubview(self.imageView)
        self.containerView.addSubview(self.titleLabel)
        self.containerView.addSubview(self.subtitleLabel)

        self.setUpImageView()
        self.setUpTitleLabel()
        self.setUpSubtitleLabel()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()

        self.imageView.pin
            .topCenter()
            .sizeToFit()

        self.titleLabel.pin
            .below(of: self.imageView, aligned: .center)
            .marginTop(4)
            .sizeToFit()

        self.subtitleLabel.pin
            .below(of: self.titleLabel, aligned: .center)
            .marginTop(4)
            .sizeToFit()

        self.containerView.pin
            .wrapContent()
            .center()
    }

    private func setUpImageView() {
        self.imageView.contentMode = .scaleAspectFit
    }

    private func setUpTitleLabel() {
        self.titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold).rounded()
        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = .center
        self.titleLabel.lineBreakMode = .byTruncatingMiddle
    }

    private func setUpSubtitleLabel() {
        self.subtitleLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular).rounded()
        self.subtitleLabel.numberOfLines = 0
        self.subtitleLabel.textAlignment = .center
        self.subtitleLabel.textColor = UIColor.secondaryLabel
    }

}

