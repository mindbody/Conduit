//
//  ViewController.swift
//  ConduitExample
//
//  Created by John Hammerlund on 6/23/17.
//  Copyright © 2017 MINDBODY. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var statusLabel: UILabel!

    private func updateStatus(_ text: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = text
        }
    }

    @IBAction func didTapLogIn(_ sender: Any) {
        UserSessionManager.shared.logIn(username: usernameTextField.text ?? "", password: passwordTextField.text ?? "") { result in
            if let error = result.error {
                self.updateStatus("\(error)")
            }
            else {
                self.updateStatus("Logged in!")
            }
        }
    }
    @IBAction func didTapFetchUser(_ sender: Any) {
        ProtectedResourceService().fetchThing { result in
            switch result {
            case .error(let error):
                self.updateStatus("\(error)")
            case .value(let protectedThing):
                var status = "Protected Resource\n"
                status += "========\n"
                status += "Answer to life, universe, & everything: \(protectedThing.secretThing)\n"
                self.updateStatus(status)
            }
        }
    }

    @IBAction func didTapLogOut(_ sender: Any) {
        UserSessionManager.shared.logOut()
        updateStatus("Logged out!")
    }
}

