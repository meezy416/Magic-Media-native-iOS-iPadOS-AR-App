//
//  ReportContentHelper.swift
//  MagicKettle
//

import UIKit
import Supabase

/// Presents a reason picker and files a report against a trigger's `reports` row.
/// Required alongside the pending-approval queue for App Store Guideline 1.2 (UGC apps
/// need a way for users to flag objectionable content).
enum ReportContentHelper {

    private static let reasons = [
        "Inappropriate content",
        "Copyright infringement",
        "Spam or misleading",
        "Other"
    ]

    static func presentReportFlow(for trigger: Trigger, from presenter: UIViewController) {
        let picker = UIAlertController(
            title: "Report \"\(trigger.title)\"",
            message: "Why are you reporting this?",
            preferredStyle: .actionSheet
        )

        for reason in reasons {
            picker.addAction(UIAlertAction(title: reason, style: .default) { _ in
                submitReport(trigger: trigger, reason: reason, presenter: presenter)
            })
        }
        picker.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        presenter.present(picker, animated: true)
    }

    private static func submitReport(trigger: Trigger, reason: String, presenter: UIViewController) {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let report = NewReport(triggerId: trigger.id, reporterId: session.user.id, reason: reason)

                try await SupabaseManager.shared.client
                    .from("reports")
                    .insert(report)
                    .execute()

                await MainActor.run {
                    let confirmation = UIAlertController(
                        title: "Thanks for the report",
                        message: "We'll review this content.",
                        preferredStyle: .alert
                    )
                    confirmation.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(confirmation, animated: true)
                }
            } catch {
                await MainActor.run {
                    let failure = UIAlertController(
                        title: "Couldn't send report",
                        message: "Make sure you're signed in and try again.",
                        preferredStyle: .alert
                    )
                    failure.addAction(UIAlertAction(title: "OK", style: .default))
                    presenter.present(failure, animated: true)
                }
            }
        }
    }
}
