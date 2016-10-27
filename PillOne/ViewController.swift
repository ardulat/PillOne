//
//  ViewController.swift
//  PillOne
//
//  Created by MacBook on 30.06.16.
//  Copyright © 2016 Yerzhan Mademikhanov. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var label: UILabel!
    
    var imageView: UIImage!

    var counter2 = 4200

    // next 4200 - 13000, 20000 - 20200, 73500-80000, 80000-80040
    // other indexes don't have the right info 
    
    
    @IBAction func chooseImagePressed(sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    var counter = 0
    let rootRef = FIRDatabase.database().reference()
    
    let conditionRef =  FIRDatabase.database().reference().child("condition")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.main()
    }
    
    @IBAction func submitPressed(sender: AnyObject) {
        
        var data: NSData = NSData()
        if let image = self.imageView {
            data = UIImageJPEGRepresentation(image, 0.5)!
        }
        
        let base64String = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
        
        let dict: NSDictionary = ["condition": label.text!, "image":base64String]
        
        let newRef = rootRef.childByAutoId()
        newRef.setValue(dict)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.imageView = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        conditionRef.observeEventType(.Value) {
            (snap: FIRDataSnapshot) in
            self.label.text = snap.value?.description!
        }

    }
    
    @IBAction func sunnyPressed(sender: AnyObject) {
        let newRef = self.rootRef.childByAutoId()
        newRef.setValue("Sunny \(counter)")
        conditionRef.setValue("Sunny")
        counter += 1
    }
    
    @IBAction func foggyPressed(sender: AnyObject) {
        let newRef = self.rootRef.childByAutoId()
        newRef.setValue("Foggy \(counter)")
        conditionRef.setValue("Foggy")
        counter += 1
    }
    
    func saveToFile(text: String, file: String) {
        if let dir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first {
            let path = NSURL(fileURLWithPath: dir).URLByAppendingPathComponent(file)
            
            // reading from the file
            do {
                let text2 = try NSString(contentsOfURL: path, encoding: NSUTF8StringEncoding)
                //   text = (text2 as String) + text
            } catch {
                print("Could not read from the file =(")
            }
            
            // writing to the file
            do {
                try text.writeToURL(path, atomically: false, encoding: NSUTF8StringEncoding)
            } catch {
                print("Could not write to the file =(")
            }
        }
    }
    
    
    func download(url: String) -> String{
        
        guard let myurl = NSURL(string: url) else {
            print("Error")
            return ""
        }
        
        // try catch block
        do {
            // downloads the content of URL address
            let text = try String(contentsOfURL: myurl)
            return text
        } catch let error as NSError {
            print("Error \(error)")
        }
        
        return ""
    }
    
    func separateWords(text: String) -> [String] {
        let myArray = [Character](text.characters)
        
        var tempWord = ""
        var words = [String]()
        for ch in myArray {
            if ch == "\n" || ch == "\t" || ch == " " || ch == "\r" || ch == "&" || ch == ";" || ch == "." || ch == ","{
                if tempWord != "" {
                    words.append(tempWord)
                    tempWord = ""
                }
            } else {
                tempWord += String(ch)
            }
        }
        return words
    }
    
    func deleteHTML(text: String) -> String {
        var final = ""
        let arrayText = [Character](text.characters)
        
        var i = 0
        var size = arrayText.count
        while i < size {
            if arrayText[i] == "<" {
                var j = i + 1
                while arrayText[j] != ">" {
                    j = j + 1
                }
                i = j
                final += " "
            } else {
                final += String(arrayText[i])
            }
            i = i + 1
        }
        return final
    }
    
    func findPrice(info: String) -> Int {
        let tempArray = [Character](info.characters)
        let size = tempArray.count
        var j = 0
        for var i = 80000; i < size - 1; i += 1 {
            if tempArray[i] == "т" && tempArray[i + 1] == "г" {
                j = i
                break
            }
        }
        
        print("THe price was found at index \(j)")
        
        var go = true
        var num = 0
        var mult = 1
        // going back until digit
        while go == true {
            for var i = 0; i <= 9; i += 1 {
                if String(tempArray[j]) == String(i) {
                    var isDigit = true
                    while isDigit {
                        isDigit = false
                        for var i = 0; i <= 9; i += 1 {
                            if String(tempArray[j]) == String(i) {
                                isDigit = true
                                num = mult * i + num
                                mult *= 10
                                break
                            }
                        }
                        j -= 1
                    }
                    go = false
                }
            }
            j -= 1
        }
        return num
    }
    
    
    func haveDigit(word: String) -> Bool {
        let temp = [Character](word.characters)
        for var j = 0; j < temp.count; j++ {
            for var i = 0; i <= 9; i += 1 {
                if String(temp[j]) == String(i) {
                    return true
                }
            }
        }
        return false
    }
    
    func downloadAll() {
        var temp = ""
            print(counter2)
            temp = download("http://apteka84.kz/?page=item&id_item=\(counter2)")
        
        
        let price = findPrice(temp)
        var name = ""
        var purpose = ""
        var prohibition = ""
        var description = ""
        var activeComponents = ""
        var infoStartIndex = 0
        let words = separateWords(deleteHTML(temp))
        
        // searching for the trade name
        var startIndex = 0
        for word in words {
            startIndex += 1
            if word == "Торговое" {
                infoStartIndex = startIndex
                print("Yahoo")
                break
            }
        }
        
        var endIndex = 0
        for var i = startIndex + 1; i < words.count; i += 1 {
            if words[i] == "Международное" {
                endIndex = i
                break
            }
            
            if words[i].characters.count > 1 && words[i] != "nbsp" && words[i] != "\r\n" && words[i] != "reg" && words[i] != "minus" {
                name += words[i] + " "
            }
        }
        
        if name == "" {
            savePillAsync(name, price: price, activeComponents: activeComponents, purpose: purpose, prohibition: prohibition, description: description)
        } else {
        
            // searching for the active components
            for var i = startIndex; i < words.count; i += 1 {
                startIndex += 1
                if words[i] == "активное" || words[i] == "активные" {
                    print("Yahoo")
                    break
                }
            }
            
            for var i = startIndex + 2; i < words.count; i += 1 {
                if words[i] == "вспомогательные" || words[i] == "вспомогательное" {
                    endIndex = i
                    break
                }
                //print(words[i])
                if words[i].characters.count > 1 && words[i] != "nbsp" && words[i] != "\r\n" && haveDigit(words[i]) == false && words[i] != "мг" && words[i] != "мл" && words[i] != "reg" && words[i] != "minus" && words[i] != "ndash" {
                    activeComponents += words[i] + " "
                }
            }

            print(activeComponents)
            
        // searching for the purpose
        for var i = startIndex; i < words.count; i += 1 {
            startIndex += 1
            if words[i] == "Показания" {
                print("Yahoo")
                break
            }
        }
        
        for var i = startIndex + 2; i < words.count; i += 1 {
            if words[i] == "Способ" {
                endIndex = i
                break
            }
            //print(words[i])
            if words[i].characters.count > 1 && words[i] != "nbsp" && words[i] != "\r\n" {
                purpose += words[i] + " "
            }
        }
        
        // searching for the prohibition
        for var i = startIndex; i < words.count; i += 1 {
            startIndex += 1
            if words[i] == "Противопоказания" {
                print("Yahoo")
                break
            }
        }
        
        for var i = startIndex + 1; i < words.count; i += 1 {
            if words[i] == "Лекарственные" {
                endIndex = i
                break
            }
            
            if words[i].characters.count > 1 && words[i] != "nbsp" && words[i] != "\r\n" {
                prohibition += words[i] + " "
            }
        }
        
            for var i = infoStartIndex; i < words.count; i += 1 {
                description += words[i] + " "
            }
        
            savePillAsync(name, price: price, activeComponents: activeComponents, purpose: purpose, prohibition: prohibition, description: description)
        }
    }
    
    
    func savePill(name: String, price: Int, activeComponents: String, purpose: String, prohibition: String, description: String) {
        let newRef = FIRDatabase.database().reference().childByAutoId()
        let dict: NSDictionary = ["name": name, "price": price, "activeComponents": activeComponents, "purpose": purpose, "prohibition": prohibition, "description": description]
        newRef.setValue(dict)
    }
    
    func savePillAsync(name: String, price: Int, activeComponents: String, purpose: String, prohibition: String, description: String) {
        let pill = Pill()
        
        pill.name = name.substringToIndex(name.startIndex.advancedBy(min(name.characters.count, 400)))
        pill.price = price
        pill.purpose = purpose.substringToIndex(purpose.startIndex.advancedBy(min(purpose.characters.count, 400)))
        pill.prohibition = prohibition.substringToIndex(prohibition.startIndex.advancedBy(min(prohibition.characters.count, 400)))

        pill.activeComponents = activeComponents.substringToIndex(activeComponents.startIndex.advancedBy(min(activeComponents.characters.count, 400)))
        
        
        
        let dataStore = Backendless.sharedInstance().data.of(Pill.ofClass())

        // save object asynchronously
        if pill.name!.characters.count > 0 {
        dataStore.save(
            pill,
            response: { (result: AnyObject!) -> Void in
                let obj = result as! Pill
                print("Pill has been saved: \(obj.objectId)")
                
                // saving to Firebase
                let newRef = FIRDatabase.database().reference().child("pills/\(obj.objectId!)")
                newRef.setValue(description)
                self.counter2 += 1
                self.downloadAll()
            },
            error: { (fault: Fault!) -> Void in
                print("fServer reported an error: \(fault)")
        })
        } else {
            self.counter2 += 1
            self.downloadAll()
        }
    }
    
    func main() {
        downloadAll()
    }
    
 
    // ПОКА НЕНУЖНЫЙ КОД
    
    func deleteRedundancy() {
            let dataStore = Backendless.sharedInstance().data.of(Pill.ofClass())
            let dataQuery = BackendlessDataQuery()
            dataQuery.whereClause = "name = '' "
            var counter = 0
            dataStore.find(dataQuery,
                response: { (result: BackendlessCollection!) -> Void in
                    let contacts = result.getCurrentPage()
                    for obj in contacts {
                        let pill = obj as! Pill
                        
                        print("\(obj)")
                        dataStore.remove(
                            obj,
                            response: { (result: AnyObject!) -> Void in
                                print("Pill has been removed: \(result)")
                                counter += 1
                                if counter == contacts.count {
                                    self.deleteRedundancy()
                                }
                            },
                            error: { (fault: Fault!) -> Void in
                                print("Server reported an error (2): \(fault)")
                        })
                    }
                },
                error: { (fault: Fault!) -> Void in
                    print("Server reported an error: \(fault)")
            })
    }
 }

