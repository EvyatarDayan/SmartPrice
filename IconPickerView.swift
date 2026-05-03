import SwiftUI
import PhotosUI

struct IconPickerView: View {
    @Binding var selectedIconName: String?
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    private let productIcons = [
        ("creditcard", "Credit Card"),
        ("display", "Monitor/Screen"),
        ("music.note", "Musical Note"),
        ("apple.logo", "Apple Logo"),
        ("paintbrush", "Paint Brush"),
        ("figure.run", "Running Person"),
        ("wifi", "Wi-Fi"),
        ("bolt", "Lightning Bolt"),
        ("phone", "Phone Receiver"),
        ("house", "House/Home"),
        ("car", "Car"),
        ("gamecontroller", "Game Controller"),
        ("book", "Open Book"),
        ("graduationcap", "Graduation Cap"),
        ("heart", "Heart"),
        ("plus", "Plus Sign"),
        ("pills", "Pills"),
        ("stethoscope", "Stethoscope"),
        ("building", "Building"),
        ("cart", "Shopping Cart"),
        ("briefcase", "Briefcase/Bag"),
        ("gift", "Gift Box"),
        ("star", "Star"),
        ("crown", "Crown"),
        ("diamond", "Diamond"),
        ("leaf", "Leaf"),
        ("flame", "Flame/Fire"),
        ("drop", "Water Drop"),
        ("snowflake", "Snowflake"),
        ("sun.max", "Sun"),
        ("moon", "Moon"),
        ("cloud", "Cloud"),
        ("umbrella", "Umbrella")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(productIcons, id: \.0) { icon in
                        VStack(spacing: 8) {
                            Image(systemName: icon.0)
                                .font(.system(size: 40))
                                .foregroundColor(selectedIconName == icon.0 ? .white : .blue)
                                .frame(width: 80, height: 80)
                                .background(
                                    selectedIconName == icon.0 ? 
                                    Color.blue : Color.blue.opacity(0.1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Text(icon.1)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            selectedIconName = icon.0
                            selectedImage = nil // Clear any selected image when choosing an icon
                            isPresented = false // Close the modal automatically
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedIconName: String?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                        self.parent.selectedIconName = nil // Clear any selected icon when photo is chosen
                    }
                }
            }
        }
    }
}
