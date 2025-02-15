import UIKit

extension UIViewController {

    func showAlert(title: String, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "Ok", style: .default))

        self.present(alertController, animated: true)
    }

}


