//
//  CameraViewController.swift
//  Instagram
//
//  Created by Bryan Santos on 3/10/22.
//

import UIKit
import AlamofireImage
import Parse

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var captionTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print()
    }
    
    @IBAction func onCameraImageTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func onBarButtonImageTap(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        let post = PFObject(className: "Posts")
        let imageData = cameraImageView.image?.pngData()
        let imageName = ((cameraImageView.image?.accessibilityIdentifier) ?? "") as String
        let file = PFFileObject(name: "image.png", data: imageData!)
        
        
        if imageName != "image_placeholder" {
            post["caption"] = captionTextField.text
            post["author"] = PFUser.current()
            post["image"] = file
            
            post.saveInBackground { success, error in
                if success {
                    self.dismiss(animated: true, completion: nil)
                    print("success!")
                } else {
                    print("\(error?.localizedDescription ?? "")")
                }
            }
        } else {
            let alert = UIAlertController(title: "Uh Oh!", message: "you haven't chosen a photo yet", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.editedImage] as! UIImage
        let size = CGSize(width: 375, height: 375)
        let scaledImage = image.af.imageScaled(to: size)
        
        cameraImageView.image = scaledImage
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
