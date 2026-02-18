//
//  ContactPickerView.swift
//  Nourish
//

import SwiftUI
import ContactsUI

/// A result carrying the fields we care about from a picked contact.
struct PickedContact {
    var name: String
    var phoneNumber: String
    var photoData: Data?
}

/// A button that presents CNContactPickerViewController when tapped.
struct ContactPickerButton<Label: View>: UIViewControllerRepresentable {

    let label: Label
    let onPick: (PickedContact) -> Void

    init(onPick: @escaping (PickedContact) -> Void, @ViewBuilder label: () -> Label) {
        self.onPick = onPick
        self.label = label()
    }

    func makeUIViewController(context: Context) -> ContactPickerHostController<Label> {
        ContactPickerHostController(label: label, coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: ContactPickerHostController<Label>, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onPick: (PickedContact) -> Void

        init(onPick: @escaping (PickedContact) -> Void) {
            self.onPick = onPick
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            let photoData = contact.imageDataAvailable ? contact.imageData : nil

            let picked = PickedContact(name: name, phoneNumber: phone, photoData: photoData)

            DispatchQueue.main.async { [self] in
                onPick(picked)
            }
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            // Nothing needed - picker dismisses itself
        }
    }
}

/// Host controller that wraps a SwiftUI label and presents the contact picker.
final class ContactPickerHostController<Label: View>: UIViewController {

    private var hostingController: UIHostingController<Button<Label>>!
    private weak var coordinator: ContactPickerButton<Label>.Coordinator?

    init(label: Label, coordinator: ContactPickerButton<Label>.Coordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)

        let button = Button(action: { [weak self] in
            self?.presentPicker()
        }) {
            label
        }

        hostingController = UIHostingController(rootView: button)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear
        view.backgroundColor = .clear

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    private func presentPicker() {
        let picker = CNContactPickerViewController()
        picker.delegate = coordinator
        present(picker, animated: true)
    }
}
