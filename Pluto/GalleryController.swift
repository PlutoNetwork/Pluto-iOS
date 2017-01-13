//
//  GalleryController.swift
//  Pluto
//
//  Created by Faisal M. Lalani on 1/12/17.
//  Copyright © 2017 Faisal M. Lalani. All rights reserved.
//

import UIKit
import Firebase
import FMMosaicLayout

private let reuseIdentifier = "imageCell"

class GalleryController: UICollectionViewController, UINavigationControllerDelegate, FMMosaicLayoutDelegate {

    // MARK: - VARIABLES
    
    var navigationBarAddButton: UIBarButtonItem!
    var imagePicker: UIImagePickerController!
    
    /// Holds the key of the event passed in from the detail controller.
    var eventKey = String()
    
    /// Holds the images under the current event.
    var images = [Image]()
    
    // MARK: - VIEW
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        /* Navigation bar customization. */
        self.navigationController?.setNavigationBarHidden(false, animated: true) // Keeps the navigation bar unhidden.
        self.navigationItem.title = "Pictures" // Sets the title of the navigation bar.
        self.navigationController?.navigationBar.tintColor = UIColor.white // Turns the contents of the navigation bar white.
        
        /* Add image button */
        navigationBarAddButton = UIBarButtonItem(image: UIImage(named: "ic-add"), style: .plain, target: self, action: #selector(GalleryController.addImage))
        navigationBarAddButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem  = navigationBarAddButton
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Initialization of the image picker. */
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        
        /// Holds an instance of the mosaic layout's library.
        let mosaicLayout: FMMosaicLayout = FMMosaicLayout()
        self.collectionView?.collectionViewLayout = mosaicLayout // Sets the collection view's layout to the new mosaic layout.

        grabImages()
        
    }
    
    // MARK: - FIREBASE
    
    /**
     *  Uses the keys received from under the current board's data reference to find and grab the data relating to the keys.
     */
    func grabImages() {
        
        DataService.ds.REF_EVENTS.child(eventKey).child("gallery").observe(.value, with: { (snapshot) in
            
            self.images = [] // Clears the array to avoid duplicates.
            
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                
                for snap in snapshot {
                    
                    if let imageDict = snap.value as? Dictionary<String, AnyObject> {
                        
                        let key = snap.key
                        
                        let image = Image(imageKey: key, imageData: imageDict) // Format the data using the Image model.
                        
                        self.images.append(image) // Add the event to the images array.
                    }
                }
            }
            
            self.collectionView?.reloadData()
        })
    }

    
    /**
     *  #DATABASE
     *
     *  Creates an image using the image URL that will be added to the Firebase database.
     */
    func createImage(imageURL: String = "") {
        
        let userID = FIRAuth.auth()?.currentUser?.uid
        
        /// An event created using data pulled from the form.
        let image: Dictionary<String, Any> = [
            
            "creator": userID! as Any,
            "URL": imageURL as Any
        ]
        
        /// An image created on Firebase with a random key.
        let newImage = DataService.ds.REF_EVENTS.child(eventKey).child("gallery").childByAutoId()
        
        /// Uses the event model to add data to the event created on Firebase.
        newImage.setValue(image)
        
        /// The key for the event created on Firebase.
        let newImageKey = newImage.key
        
        /// A reference to the new image under the current user.
        let userEventRef = DataService.ds.REF_CURRENT_USER.child("images").child(newImageKey)
        
        userEventRef.setValue(true) // Sets the value to true indicating the image is under the user.
    }

    /**
     *  #STORAGE
     *
     *  Uploads the image the user selected for the event to Firebase storage.
     */
    func uploadEventImage(image: UIImage) {
        
        if let imageData = UIImageJPEGRepresentation(image, 0.2) {
            
            let imageUID = NSUUID().uuidString
            
            /// Tells Firebase storage what file type we're uploading.
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpeg"
            
            DataService.ds.REF_EVENT_PICS.child(imageUID).put(imageData, metadata: metadata) { (metadata, error) in
                
                if error != nil {
                    
                    /* ERROR: The image could not be uploaded to Firebase storage. */
                    
                    SCLAlertView().showError("Oh no!", subTitle: "There was a problem uploading the image. Please try again later.")
                    
                } else {
                    
                    /* SUCCESS: Uploaded image to Firebase storage. */
                    
                    let downloadURL = metadata?.downloadURL()?.absoluteString
                    
                    self.createImage(imageURL: downloadURL!)
                }
            }
        }
    }

    // MARK: - COLLECTION VIEW
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, numberOfColumnsInSection section: Int) -> Int {
        
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 2.0, left: 2.0, bottom: 2.0, right: 2.0)
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, interitemSpacingForSectionAt section: Int) -> CGFloat {
        
        return 2.0
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: FMMosaicLayout!, mosaicCellSizeForItemAt indexPath: IndexPath!) -> FMMosaicCellSize {
        
        var mosaicSize = indexPath.item % 2 == 0 ? FMMosaicCellSize.big : FMMosaicCellSize.small
    
        return mosaicSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let image = images[indexPath.row]
        
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? ImageCell {
                        
            if let img = BoardController.imageCache.object(forKey: image.imageURL as NSString) {
                
                cell.configureCell(image: image, img: img)
                return cell
                
            } else {
                
                cell.configureCell(image: image)
                return cell
            }
            
        } else {
            
            return UICollectionViewCell()
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        self.performSegue(withIdentifier: "showImage", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showImage" {
            
            let destinationController: ImageController = segue.destination as! ImageController
            
            let indexPath = self.collectionView?.indexPathsForSelectedItems?.first!
            let selectedImage = images[(indexPath?.row)!]
            
            if let img = BoardController.imageCache.object(forKey: selectedImage.imageURL as NSString) {
                
                destinationController.image = img
                
            } else {
                
                /* ERROR */
                
            }
        }
    }
}

extension GalleryController: UIImagePickerControllerDelegate {
    
    /**
     *  Summons the image picker.
     */
    func addImage() {
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        /* "Media" means it can be a video or an image. */
        
        /* We have to check to make sure it is an image the user picked. */
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            
            self.uploadEventImage(image: image)
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

