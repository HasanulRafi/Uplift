//
//  UploadViewController.swift
//  Uplift
//
//  Created by Matthew Rodriguez on 2/16/19.
//  Copyright © 2019 Matthew Rodriguez. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices
import Firebase

class UploadViewController: UIViewController {

    var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference(fromURL: "https://uplift-8ef8c.firebaseio.com/")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let alertController = UIAlertController(title: "Upload", message: "Would you like to use the camera?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // handle cancel response here. Doing nothing will dismiss the view.
            self.tabBarController?.selectedIndex = 4
        }
        alertController.addAction(cancelAction)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            self.launchCamera()
        }
        alertController.addAction(OKAction)
        present(alertController, animated: true)
    }
    
    func launchCamera() {
        VideoHelper.startMediaBrowser(delegate: self, sourceType: .camera)
    }

    
    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo info: AnyObject) {
        self.tabBarController?.selectedIndex = 0
        /*
        let title = (error == nil) ? "Success" : "Error"
        let message = (error == nil) ? "Video was saved to Firebase" : "Video failed to save"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        */
    }
}

extension UploadViewController: UIImagePickerControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true, completion: nil)
        
        guard
            let mediaType = info[.mediaType] as? String,
            mediaType == (kUTTypeMovie as String),
            let url = info[.mediaURL] as? URL,
            UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path)
            else {
                return
        }
        
        //TODO: Store on firebase storage
        let storage = Storage.storage()
        let uniqueId = UUID()
        let uniqueString = uniqueId.uuidString // Creates a unique string
        let storageRef = storage.reference().child("\(uniqueString).mov")
        
        storageRef.putFile(from: url as URL, metadata: nil, completion: { (metadata, error) in
            if error == nil {
                print("Successful video upload")
                storageRef.downloadURL(completion: { (downloadUrl, innerError) in
                    if let innerError = innerError {
                        print(innerError.localizedDescription)
                    } else {
                        guard let downloadUrl = downloadUrl else { return }
                        self.ref.child("a").childByAutoId().setValue(downloadUrl.absoluteString)
                        print("video was uploaded to storage and value set in database")
                        //print(downloadUrl.absoluteString)
                    }
                })
            } else {
                print(error?.localizedDescription ?? "Error was found")
            }
        })

        // Handle a movie capture
        let title = "Success"
        let message = "Video was saved to Firebase"
         
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        present(alert, animated: true, completion: nil)
        /*
        UISaveVideoAtPathToSavedPhotosAlbum(
            url.path,
            self,
            #selector(video(_:didFinishSavingWithError:contextInfo:)),
            nil)
 */
    }
}

// MARK: - UINavigationControllerDelegate
extension UploadViewController: UINavigationControllerDelegate {
}
