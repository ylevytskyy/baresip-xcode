//
//  SipCallDetailsViewController.swift
//  TareSIPDemo
//
//  Created by Yuriy Levytskyy on 2/28/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

import UIKit

class SipCallDetailsViewController : UIViewController {
    @IBOutlet weak var peerUriLabel: UILabel!
    @IBOutlet weak var peerNameLabel: UILabel!
    @IBOutlet weak var callIdLabel: UILabel!
    @IBOutlet weak var localUriLabel: UILabel!
    
    var sipCall: SipCall!

    @IBAction func hold(_ sender: Any) {
        sipCall.hold(true)
    }
    
    @IBAction func hangup(_ sender: Any) {
        sipCall.hangup(487, reason: "Request Terminated")
        
        navigationController?.popViewController(animated: true)
    }
}

extension SipCallDetailsViewController {
    override func viewDidLoad() {
        peerUriLabel.text = "Peer URI: \(sipCall.peerUri)"
        peerNameLabel.text = "Peer name: \(sipCall.peerName)"
        callIdLabel.text = "Call ID: \(sipCall.callId)"
        localUriLabel.text = "Peer URI: \(sipCall.localUri)"
    }
}
