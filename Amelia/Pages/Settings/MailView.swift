//
//  MailView.swift
//  Amii
//
//  Created by Amy Collector on 25/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {

    @Environment(\.presentationMode) var presentation
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        @Binding var presentation: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentation: Binding<PresentationMode>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            self._presentation = presentation
            self._result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                self.$presentation.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)

                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentation: self.presentation,
                           result: self.$result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        
        vc.setToRecipients(["help@amycollector.app"])
        vc.setSubject("Feedback/Help")
        
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                vc.setMessageBody("\n\n\n-----------\nPlease do not remove the text below. It will help us in assisting you.\n\nVersion: \(version)-\(build)\niOS: \(UIDevice.current.systemVersion)", isHTML: false)
            }
        }
        
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {

    }
}
