//
//  BarcodeScannerView.swift
//  SmartPrice
//
//  Created by EVYATAR DAYAN on 10/09/2025.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let scanner = ScannerViewController()
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func didFindBarcode(_ code: String) {
            parent.scannedCode = code
            parent.isPresented = false
        }
    }
}

protocol ScannerDelegate: AnyObject {
    func didFindBarcode(_ code: String)
}

class ScannerViewController: UIViewController {
    weak var delegate: ScannerDelegate?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scanningFrame: CGRect = CGRect.zero
    private var lastScanTime: Date = Date.distantPast
    private var isSessionSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    deinit {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Always ensure camera is set up when view appears
        // This fixes issues when app is reopened after being closed
        if captureSession == nil || !isSessionSetup {
            setupCamera()
        } else if let captureSession = captureSession, !captureSession.isRunning {
            // Add a small delay to ensure the view is fully loaded before starting the camera
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let captureSession = captureSession, captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        // Check camera permission first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCaptureSession()
                    } else {
                        self.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }
    
    private func setupCaptureSession() {
        // Clean up any existing session
        if let existingSession = captureSession {
            existingSession.stopRunning()
            captureSession = nil
        }
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showCameraErrorAlert()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showCameraErrorAlert()
            return
        }
        
        if let captureSession = captureSession, captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showCameraErrorAlert()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if let captureSession = captureSession, captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .pdf417, .qr]
        } else {
            showCameraErrorAlert()
            return
        }
        
        if let captureSession = captureSession {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = view.layer.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
            }
            
            // Add scanning overlay
            addScanningOverlay()
            
            // Mark session as set up
            isSessionSetup = true
            
            // Add a delay to ensure the preview layer is fully set up before starting the session
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
            }
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Permission Required",
            message: "Please enable camera access in Settings to scan barcodes.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showCameraErrorAlert() {
        let alert = UIAlertController(
            title: "Camera Error",
            message: "Unable to access camera. Please try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func addScanningOverlay() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.isUserInteractionEnabled = false
        
        // Create transparent scanning area
        let scanningArea = UIView()
        scanningArea.frame = CGRect(x: 50, y: 200, width: view.bounds.width - 100, height: 200)
        scanningArea.backgroundColor = UIColor.clear
        scanningArea.layer.borderColor = UIColor.white.cgColor
        scanningArea.layer.borderWidth = 2
        scanningArea.layer.cornerRadius = 10
        
        // Store the scanning frame for barcode detection validation
        scanningFrame = scanningArea.frame
        
        // Create mask to make scanning area transparent
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanningPath = UIBezierPath(rect: scanningArea.frame)
        path.append(scanningPath.reversing())
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        view.addSubview(overlayView)
        view.addSubview(scanningArea)
        
        // Add instruction label
        let instructionLabel = UILabel()
        instructionLabel.text = "Position barcode within the frame"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.frame = CGRect(x: 0, y: scanningArea.frame.maxY + 20, width: view.bounds.width, height: 30)
        view.addSubview(instructionLabel)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            // Check if the barcode is within the scanning frame
            if isBarcodeWithinScanningFrame(metadataObject) {
                // Add debounce to prevent multiple rapid detections
                let currentTime = Date()
                if currentTime.timeIntervalSince(lastScanTime) > 0.5 { // Reduced debounce to 0.5 seconds
                    lastScanTime = currentTime
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    delegate?.didFindBarcode(stringValue)
                }
            }
        }
    }
    
    private func isBarcodeWithinScanningFrame(_ metadataObject: AVMetadataObject) -> Bool {
        guard let previewLayer = previewLayer else { return false }
        
        // Convert metadata object bounds to preview layer coordinate system
        let transformedObject = previewLayer.transformedMetadataObject(for: metadataObject)
        guard let transformedBounds = transformedObject?.bounds else { return false }
        
        // Check if the barcode bounds intersect with the scanning frame
        return scanningFrame.intersects(transformedBounds)
    }
}
