//
//  ViewController.swift
//  CoreMLDemo
//
//  Created by Podul on 2018/1/4.
//  Copyright © 2018年 Podul. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate ,UINavigationControllerDelegate {
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var btnPhotoLibrary: UIButton!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // MARK: - Action
    // 选择图片
    @IBAction func btnClick(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        self.present(picker, animated: true, completion: nil)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imgView.image = image
            
//            analysisImageWithVision(image: image)
            analysisImageWithoutVision(image: image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Privacy
    // 分析完成后回到主线程刷新页面，并弹出提示
    func showAnalysisResultOnMainQueue(with message: String) {
        // 回到主线程
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Completed", message: message, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: {
                self.indicatorView.stopAnimating()
                self.view.isUserInteractionEnabled = true
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    
    // 只使用CoreML方法来分析
    func analysisImageWithoutVision(image: UIImage) {
        indicatorView.startAnimating()
        view.isUserInteractionEnabled = false
        
        // 子线程执行
        DispatchQueue.global(qos: .userInteractive).async {
            // 1、先把 UIImage 转为 240 x 240
            let imageWidth: CGFloat = 224.0
            let imageHeight: CGFloat = 224.0
            UIGraphicsBeginImageContext(CGSize(width:imageWidth, height:imageHeight))
            image.draw(in:CGRect(x:0, y:0, width:imageHeight, height:imageHeight))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            guard let newImage = resizedImage else {
                fatalError("resized Image fail")
            }
            
            // 2、把 UIImage 对象转成 CVPixelBuffer 对象
            guard let pixelBuffer = self.createPixelBufferFromImage(newImage) else {
                fatalError("convert PixelBuffer fail")
            }
            
            // 3、图片分析
            guard let output = try? GoogLeNetPlaces().prediction(sceneImage: pixelBuffer) else {
                fatalError("predict fail")
            }
            
            // 4、分析结果
            let result = "\(output.sceneLabel)(\(Int(output.sceneLabelProbs[output.sceneLabel]! * 100))%)"
            
            // 5、刷新页面
            self.showAnalysisResultOnMainQueue(with: result)
        }
    }
    
    // 使用CoreML+Vision方法来分析
    func analysisImageWithVision(image: UIImage) {
        indicatorView.startAnimating()
        
        view.isUserInteractionEnabled = false
        
        // 转换图片类型
        guard let ciImage = CIImage(image: image) else {
            fatalError("convert CIImage error")
        }
        
        guard let model = try? VNCoreMLModel(for: GoogLeNetPlaces().model) else {
            fatalError("load GoogLeNetPlaces model error")
        }
        
        _ = VNCoreMLRequest(model: model) { (request, error) in
            //---------------- 1----------------
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("unexpected result type")
            }
            
            // ----------------2----------------
            guard let topResult = results.first else {
                fatalError("No result!")
            }
            
            // ----------------3----------------
            let result = "\(topResult.identifier)(\(Int(topResult.confidence * 100))%)"
            //---------------- 4----------------
            self.showAnalysisResultOnMainQueue(with: result)
        }
    }
    
}

// 将一个UIImage类型的图片对象，转换成一个 CVPixelBuffer 类型的对象
extension ViewController {
    func createPixelBufferFromImage(_ image: UIImage) -> CVPixelBuffer?{
        let size = image.size
        var pxbuffer : CVPixelBuffer?
        let pixelBufferPool = createPixelBufferPool(Int32(size.width), Int32(size.height),        FourCharCode(kCVPixelFormatType_32BGRA), 2056)
        
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool!, &pxbuffer)
        
        guard (status == kCVReturnSuccess) else{
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pxdata = CVPixelBufferGetBaseAddress(pxbuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(data: pxdata,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(pxbuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxbuffer
    }
    
    func createPixelBufferPool(_ width: Int32, _ height: Int32, _ pixelFormat: FourCharCode, _ maxBufferCount: Int32) -> CVPixelBufferPool? {
        
        var outputPool: CVPixelBufferPool? = nil
        
        let sourcePixelBufferOptions: NSDictionary = [kCVPixelBufferPixelFormatTypeKey: pixelFormat,
                                                      kCVPixelBufferWidthKey: width,
                                                      kCVPixelBufferHeightKey: height,
                                                      kCVPixelFormatOpenGLESCompatibility: true,
                                                      kCVPixelBufferIOSurfacePropertiesKey: NSDictionary()]
        
        let pixelBufferPoolOptions: NSDictionary = [kCVPixelBufferPoolMinimumBufferCountKey: maxBufferCount]
        
        CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions,        sourcePixelBufferOptions, &outputPool)
        return outputPool
    }
}

