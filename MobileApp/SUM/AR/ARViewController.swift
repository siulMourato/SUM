//
//  ARViewController.swift
//  SUM
//
//  Created by Enrico Florentino Gomes on 03/01/2022.
//  Updated by Luis Sousa on 18/01/2022

import UIKit
import RealityKit
import ARKit

class ARViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    let networkManager = NetworkManager()
    var bus:Entity?
    var progressBar:Entity?
    var loadBus:Int? = nil
    var timer:Timer?
    var capacity = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the AR session for horizontal plane tracking
        let arConfiguration = ARWorldTrackingConfiguration()
        arConfiguration.planeDetection = .horizontal
        arView.session.run(arConfiguration)
        
        // Load the BusScene from the "Experience" Reality File
        let busScene = try! Experience.loadBusScene()
        bus = busScene.bus!
        
        // Add the BusScene anchor to the scene
        arView.scene.anchors.append(busScene)
        
        //Remove useless bars
        progressBar = busScene.progress
        progressBar?.children.remove((progressBar?.children[0])!)
        progressBar?.children.remove((progressBar?.children[1])!)
        progressBar?.children.remove((progressBar?.children[1])!)
        progressBar?.children.remove((progressBar?.children[2])!)
        
        ///Default Params:
        //Control variables
        var description = "Erro - Falha ao carregar"
   
        
        //3D Model variables - Bar
        let barEntity : Entity = (progressBar?.children[1].children[0])!
        var barModelComp: ModelComponent = (barEntity.components[ModelComponent.self])!
        var barMaterial = SimpleMaterial()
        barMaterial.color = .init(tint: (self.hexStringToUIColor(hex: "#222222"))).self
        barModelComp.materials[0] = barMaterial
        
        //3D Model variables - Text
        let valueEntity: Entity = (progressBar?.children[0].children[0].children[0])!
        var valueModelComp: ModelComponent = (valueEntity.components[ModelComponent.self])!
        var valueMaterial = SimpleMaterial()
        valueMaterial.color = .init(tint: (self.hexStringToUIColor(hex: "#FFFFFF"))).self
        valueModelComp.materials[0] = valueMaterial
        
        //Set default 3D model parameters
        valueModelComp.mesh = .generateText("\(description)",
                                            extrusionDepth: 0.001,
                                            font: .systemFont(ofSize: 0.03),
                                            containerFrame: CGRect(),
                                            alignment: .left,
                                            lineBreakMode: .byCharWrapping)
        
        progressBar?.children[0].children[0].children[0].components.set(valueModelComp)
        progressBar?.children[1].children[0].components.set(barModelComp)
        
        //if no bus was sent to be loaded from Buses view, then load number 5
        if loadBus==nil{
            loadBus=5 //random choice of id -> TODO: change to nearest bus
        }
        
        //HTTP Request
        networkManager.fetchBus(busNumber: loadBus) { [weak self] (bus) in
            DispatchQueue.main.async { [self] in
                //Handle requested data
                self!.capacity = bus.first!.Bus_Capacity
                if(self!.capacity<40){
                    barMaterial.color = .init(tint: (self?.hexStringToUIColor(hex: "#3e9a2c"))!).self
                    description="Vazio - Lotação: \(self!.capacity)%"
                    barEntity.scale = [1,1+Float(self!.capacity/80),1]
                } else if (self!.capacity>=40&&self!.capacity<=60) {
                    barMaterial.color = .init(tint: (self!.hexStringToUIColor(hex: "#e1cd00"))).self
                    description="Médio - Lotação: \(self!.capacity)%"
                    barEntity.scale = [1,1.25+Float(self!.capacity/90),1]
                } else {
                    barMaterial.color = .init(tint: (self!.hexStringToUIColor(hex: "#bb1111"))).self
                    description="Cheio - Lotação: \(self!.capacity)%"
                    barEntity.scale = [1,1.5+Float(self!.capacity/100),1]
                }
                barModelComp.materials[0] = barMaterial
                
                //Set 3D model updated parameters
                valueModelComp.mesh = .generateText("\(description)",
                                                    extrusionDepth: 0.001,
                                                    font: .systemFont(ofSize: 0.03),
                                                    containerFrame: CGRect(),
                                                    alignment: .left,
                                                    lineBreakMode: .byCharWrapping)
                
                self!.progressBar?.children[0].children[0].children[0].components.set(valueModelComp)
                self!.progressBar?.children[1].children[0].components.set(barModelComp)
            }
        }
    }
    
    @IBAction func scaleModel(_ sender: UIButton) {
        let command = sender.titleLabel!.text?.lowercased() ?? ""
        
        switch command{
        case "+":
            if bus!.scale.x < 1 {
                bus?.scale = [bus!.scale.x+0.5, bus!.scale.y+0.5, bus!.scale.z+0.5]
                progressBar?.scale = [progressBar!.scale.x+0.5, progressBar!.scale.y+0.5, progressBar!.scale.z+0.5]
            }
        case "-":
            if bus!.scale.x > 0.5 {
                bus?.scale = [bus!.scale.x-0.5, bus!.scale.y-0.5, bus!.scale.z-0.5]
                progressBar?.scale = [progressBar!.scale.x-0.5, progressBar!.scale.y-0.5, progressBar!.scale.z-0.5]
            }
        default:
            break;
        }
    }
    
    @IBAction func buttonRotateDown(_ sender: UIButton) {
        let command = sender.titleLabel!.text?.lowercased() ?? ""
        
        switch command{
        case "left":
            //rotateLeft()
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(rotateLeft), userInfo: nil, repeats: true)
        case "right":
            //rotateRight()
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(rotateRight), userInfo: nil, repeats: true)
        default:
            break;
        }
    }
    
    @IBAction func buttonRotateUp(_ sender: UIButton) {
        timer?.invalidate()
    }
    
    @objc func rotateLeft(){
        bus?.move(to: Transform(pitch: 0, yaw: -0.1, roll: 0), relativeTo: bus!)
        progressBar?.move(to: Transform(pitch: 0, yaw: -0.1, roll: 0), relativeTo: progressBar!)
    }
    
    @objc func rotateRight(){
        bus?.move(to: Transform(pitch: 0, yaw: 0.1, roll: 0), relativeTo: bus!)
        progressBar?.move(to: Transform(pitch: 0, yaw: 0.1, roll: 0), relativeTo: progressBar!)
    }
    
    @IBAction func likeButtonPressed(_ sender: UIButton) {
        let command = sender.titleLabel!.text?.lowercased() ?? ""
        
        switch command{
        case "like":
            print("like")
            let uploadDataModel = UserBusAR_Feedback(Bus_Id: Int(bus!.id), Bus_Name: bus!.name, Takes_Bus: 1, Bus_Ocupation: capacity)
            networkManager.putMethod(userFeedback: uploadDataModel)
            showModal()
        case "dislike":
            print("dislike")
            let uploadDataModel = UserBusAR_Feedback(Bus_Id: Int(bus!.id), Bus_Name: bus!.name, Takes_Bus: 0, Bus_Ocupation: capacity)
            networkManager.putMethod(userFeedback: uploadDataModel)
            showModal()
        default:
            break;
        }
    }
    
    func showModal()
    {
        //insert PUT API for like here
        // Create new Alert
        var dialogMessage = UIAlertController(title: "Ok", message: "Obrigado pelo seu feedback, ", preferredStyle: .alert)
        
        // Create OK button with action handler
        let ok = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
         })
        
        //Add OK button to a dialog message
        dialogMessage.addAction(ok)

        // Present Alert to
        self.present(dialogMessage, animated: true, completion: nil)
    }
    //function to convert Hex value to UIColor class
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}
