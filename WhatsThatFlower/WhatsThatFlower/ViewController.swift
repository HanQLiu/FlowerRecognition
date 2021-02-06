//
//  ViewController.swift
//  WhatsThatFlower
//
//  Created by Hanqing Liu on 1/10/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController {
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    let imagePickerController = UIImagePickerController()
    
    @IBOutlet weak var flowerNameLabel: UILabel!
    @IBOutlet weak var flowerDescriptionLabel: UILabel!
    
    @IBAction func cameraClicked(_ sender: UIBarButtonItem) {
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePickerController.delegate = self
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = true
    }
}

extension ViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            
            guard let convertedCIImage = CIImage(image: userPickedImage) else {
                fatalError("Can't convert UIImage to CIImage")
            }
            
            detect(ciimage: convertedCIImage)
            
            imagePickerController.dismiss(animated: true, completion: nil)
        }
    }
    
    func detect(ciimage: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Can't import model")
        }
        
        let request = VNCoreMLRequest(model: model) { (vnRequest, error) in
            guard let classification = vnRequest.results?.first as? VNClassificationObservation else {
                fatalError("Can't classify image")
            }
            self.flowerNameLabel.text = classification.identifier.capitalized
            self.wikiRequest(flowerName: classification.identifier)
        }
        
        let handler = VNImageRequestHandler(ciImage: ciimage)
        
        do {
            try handler.perform([request])
        } catch {
            print("Can't perform image recognition: \(error)")
        }
    }
    
    func wikiRequest(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize": "500"
        ]
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let flowerJSONFromWiki: JSON = JSON(response.result.value)
                let pageId = flowerJSONFromWiki["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSONFromWiki["query"]["pages"][pageId]["extract"].stringValue
                print(flowerDescription)
                self.flowerDescriptionLabel.text = flowerDescription
                
                // Get image using SDWebImage
                let flowerImageURL = flowerJSONFromWiki["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
            }
        }
    }
}
