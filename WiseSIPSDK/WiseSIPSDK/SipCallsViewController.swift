//
//  SipCallsViewController.swift
//  TareSIPDemo
//
//  Created by Yuriy Levytskyy on 2/26/19.
//  Copyright © 2019 Yuriy Levytskyy. All rights reserved.
//

import UIKit

class SipCallsViewController: UIViewController {
    @IBOutlet weak var remoteUri: UITextField!
    @IBOutlet weak var callsTableView: UITableView!
    @IBOutlet weak var logsTextView: UITextView!
    
    private var client = SipClient(username: "tiger333", domain: "iptel.org")
    private var calls = [SipCall]()
    
    @IBAction func connect(_ sender: Any) {
        let sipCall = client.makeCall(remoteUri.text!)
        appendCall(sipCall)
    }

    @IBAction func register(_ sender: Any) {
        client.registry()
    }
    
    @IBAction func unregister(_ sender: Any) {
        client.unregister();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        callsTableView.dataSource = self

        client.delegate = self
        client.password = "popup"
        client.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sipCallDetailsSegue" {
            let calls = Array(self.calls)
            let path = callsTableView.indexPathForSelectedRow!
            let destination = segue.destination as! SipCallDetailsViewController
            destination.sipCall = calls[path.row]
        }
    }
}

extension SipCallsViewController {
    private func appendCall(_ sipCall: SipCall) {
        calls.append(sipCall)
        sipCall.delegate = self
        callsTableView.reloadData()
    }
    
    private func clearCall(_ sipCall: SipCall) {
        if let index = calls.firstIndex(of: sipCall) {
            calls.remove(at: index)
        }
        
        callsTableView.reloadData()
    }
}

extension SipCallsViewController : SipClientDelegate {
    func onRegistering(_ sipSdk: SipClient) {
        logsTextView.text += "Registering...\n";
    }

    func onRegistered(_ sipSdk: SipClient) {
        logsTextView.text += "Registered\n";
    }

    func onFailedRegister(_ sipSdk: SipClient) {
        logsTextView.text += "Failed to register\n";
    }

    func onUnRegistering(_ sipSdk: SipClient) {
        logsTextView.text += "Unregistering...\n";
    }

    func onCallIncoming(_ sipCall: SipCall) {
        logsTextView.text += "Incomming call from \(sipCall.peerUri)...\n";

        let alertController = UIAlertController(title: sipCall.peerUri, message: "Incoming Call", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Answer", style: .default) { _ in
            sipCall.answer()
        })
        alertController.addAction(UIAlertAction(title: "Hold", style: .default) { _ in
            sipCall.holdAnswer()
        })
        alertController.addAction(UIAlertAction(title: "Decline", style: .default) { _ in
            sipCall.hangup(486, reason: "Busy Here")
        })

        self.present(alertController, animated: true, completion: nil)

        appendCall(sipCall)
    }

    func onCallRinging(_ sipCall: SipCall) {
        logsTextView.text += "Call ringing from \(sipCall.peerUri)...\n";
    }

    func onCallProcess(_ sipCall: SipCall) {
        logsTextView.text += "Call process from \(sipCall.peerUri)...\n";
    }

    func onCallEstablished(_ sipCall: SipCall) {
        logsTextView.text += "Call established from \(sipCall.peerUri)...\n";
    }

    func onCallClosed(_ sipCall: SipCall) {
        logsTextView.text += "Call closed from \(sipCall.peerUri)...\n";

        clearCall(sipCall)
    }
}

extension SipCallsViewController : SipCallDelegate {
    func onClosed(_ sipCall: SipCall) {
        logsTextView.text += "Call closed from \(sipCall.peerUri)...\n";
        
        clearCall(sipCall)
    }
}

extension SipCallsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return calls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellId", for: indexPath) as! CallCell
        let sipCall = calls[indexPath.row]
        cell.remoteUriLabel.text = sipCall.peerUri
        return cell
    }
}
