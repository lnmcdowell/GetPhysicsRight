//
//  GameViewController.swift
//  GetPhysicsRight
//
//  Created by Larry Mcdowell on 3/5/20.
//  Copyright © 2020 Larry Mcdowell. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController, SCNSceneRendererDelegate {

    var vectorDisplayNode:SCNNode!
    var windAngleVariable:Float = -25
    var ship:SCNNode!
    var scene:SCNScene!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        scene.isPaused = false
        // animate the 3d object
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        scnView.isPlaying = true
        scnView.delegate = self
        // configure the view
        scnView.backgroundColor = UIColor.black
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        ship.physicsBody?.momentOfInertia = SCNVector3Make(8, 8, 20)
        
        vectorDisplayNode = showVector(fromVector: SCNVector3Zero, toVector: SCNVector3Make(0, 1, 0))
        scene.rootNode.addChildNode(vectorDisplayNode)
        //ship.parent?.addChildNode(vectorDisplayNode)
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it

        }
        
        windAngleVariable += 20
    }
    
     func showVector(fromVector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNNode{
    
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

       let myGeo = SCNGeometry(sources: [source], elements: [element])
        
        //SCNBox(width: 1, height: 1, length: 200, chamferRadius: 1)
        
        let material = SCNMaterial()
    
         material.diffuse.contents = UIColor(red: 0.9294, green: 0.651, blue: 0, alpha: 0.4)
         myGeo.materials = [material]
         let thisNode = SCNNode.init(geometry: myGeo)
       //thisNode.pivot = SCNMatrix4MakeTranslation(0, 0, -100) //pivot is at center by default
         thisNode.physicsBody?.collisionBitMask = -9
         return thisNode
     }
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    
    //MARK - ApplyForce Knowledge
    
    // force: and at: are both in local coordinate system
     func ghgrenderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
   
        let rollForce = SCNVector3Make(0, 100, 0)
        //let translatedRollForce = ship.presentation.convertVector(rollForce, to: scene.rootNode)

        //ship.physicsBody?.applyForce(rollForce, at: SCNVector3Make(20, 0, 0), asImpulse: false)
        
        let pitchForce = SCNVector3Make(0, 100, 0)
        var angleBetweenPFPlane = pitchForce.angleBetweenVectors(ship.presentation.worldFront)
        let pitchTorqueForce = 100 * sin(angleBetweenPFPlane)
        let upForceTryTorque = SCNVector4(1,0,0,pitchTorqueForce)
        //ship.physicsBody?.applyForce(pitchForce, at: SCNVector3Make(0, 0, 20), asImpulse: false)
               
  //MARK: -  wind from side
        
        var windForce = SCNVector3Make(300, 0, 0)
        windForce = yRotateVector(forceVector: windForce, radians: windAngleVariable * .pi / 180)
        
        var angleBetweenWindAndShipForward = windForce.angleBetweenVectors(ship.presentation.worldFront)
        if angleBetweenWindAndShipForward.isNaN {
            angleBetweenWindAndShipForward = 0
        }
        windForce *= -cos(angleBetweenWindAndShipForward + .pi/2)
        
       // print("strength: \(windForce.magnitude) at \(angleBetweenWindAndShipForward * 180 / .pi), z: \(renderer.pointOfView?.position.z)")
        var translatedWindForce = scene.rootNode.convertVector(windForce, to: ship.presentation)
     //   let upForceTryTorque = SCNVector4(1,0,0,-translatedWindForce.y)
        
        //print(translatedWindForce)
        print("\(angleBetweenWindAndShipForward * 180 / .pi), force \(pitchTorqueForce)")
        translatedWindForce.y = 0
        var rudderForce = SCNVector3Make(100, 0, 0)
        //ship.physicsBody?.applyForce(rudderForce, at: SCNVector3Make(0, 0, 20), asImpulse: false)
        
        let rudderLocation = SCNVector3Make(0, 0, 20)
        let elevatorLocation = SCNVector3Make(0, 0, 19)
        
       
        ship.physicsBody?.applyForce(translatedWindForce, at: rudderLocation, asImpulse: true)
               
        ship.physicsBody?.applyTorque(upForceTryTorque, asImpulse: true)
        //ship.physicsBody?.applyForce(upForceTry, at: rudderLocation, asImpulse: true)
        renderer.pointOfView?.position.z = ship.presentation.position.z + 40
        }
    
      func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
     
          let rollForce = SCNVector3Make(0, 100, 0)
          //let translatedRollForce = ship.presentation.convertVector(rollForce, to: scene.rootNode)

          //ship.physicsBody?.applyForce(rollForce, at: SCNVector3Make(20, 0, 0), asImpulse: false)
          
          let pitchForce = SCNVector3Make(0, 100, 0)
          //ship.physicsBody?.applyForce(pitchForce, at: SCNVector3Make(0, 0, 20), asImpulse: false)
                 
    //MARK: -  wind from side
          
          var windForce = SCNVector3Make(300, 10, 0)
          windForce = yRotateVector(forceVector: windForce, radians: windAngleVariable * .pi / 180)
          
          var angleBetweenWindAndShipForward = windForce.angleBetweenVectors(ship.presentation.worldFront)
          if angleBetweenWindAndShipForward.isNaN {
              angleBetweenWindAndShipForward = 0
          }
          windForce *= -cos(angleBetweenWindAndShipForward)// + .pi/2) //this line changed to make Torque agree, it was .pi/2 for applyForce below
        
         // print("strength: \(windForce.magnitude) at \(angleBetweenWindAndShipForward * 180 / .pi), z: \(renderer.pointOfView?.position.z)")
          var translatedWindForce = scene.rootNode.convertVector(windForce, to: ship.presentation)
         
          
       
         // translatedWindForce.y = 0
          var rudderForce = SCNVector3Make(100, 0, 0)
          //ship.physicsBody?.applyForce(rudderForce, at: SCNVector3Make(0, 0, 20), asImpulse: false)
          
          let rudderLocation = SCNVector3Make(0, 0, 20)
          let elevatorLocation = SCNVector3Make(0, 0, 19)
          
         
       //   ship.physicsBody?.applyForce(translatedWindForce, at: rudderLocation, asImpulse: true)
        var signOfTorque:Float = 1
        if angleBetweenWindAndShipForward - (.pi/2) < 0 {
            print("negative")
            signOfTorque = -1
        }
        ship.physicsBody?.applyTorque(SCNVector4Make(0, 1, 0, translatedWindForce.magnitude * 30 * -signOfTorque), asImpulse: false)
       
          renderer.pointOfView?.position.z = ship.presentation.position.z + 40
        
        vectorDisplayNode.removeFromParentNode()
        //vectorDisplayNode = showVector(fromVector: ship.presentation.position, toVector: windForce)
       //
        //ship.presentation.convertVector(windForce, to: renderer.scene?.rootNode)
        vectorDisplayNode = CylinderLine(parent: ship.presentation, v1: windForce + ship.presentation.position, v2: SCNVector3Zero, radius: 0.6, radSegmentCount: 8, color: .blue)
         renderer.scene?.rootNode.addChildNode(vectorDisplayNode)
          }
    func yRotateVector(forceVector:SCNVector3, radians:Float) -> SCNVector3{

        let intVector = SCNVector3Make(forceVector.x * sin(radians) + forceVector.z * cos(radians), forceVector.y, forceVector.x * cos(radians) + forceVector.z * sin(radians) )
        return intVector
    }
}


extension SCNVector3 {
    
    /// Calculate the magnitude of this vector
    var magnitude:SCNFloat {
        get {
            return sqrt(dotProduct(self))
        }
    }
    
    /// Vector in the same direction as this vector with a magnitude of 1
    var normalized:SCNVector3 {
        get {
            let localMagnitude = magnitude
            let localX = x / localMagnitude
            let localY = y / localMagnitude
            let localZ = z / localMagnitude
            
            return SCNVector3(localX, localY, localZ)
        }
    }
    
    /**
     Calculate the dot product of two vectors
     
     - parameter vectorB: Other vector in the calculation
     */
    func dotProduct(_ vectorB:SCNVector3) -> SCNFloat {
        
        return (x * vectorB.x) + (y * vectorB.y) + (z * vectorB.z)
    }
    
    /**
     Calculate the dot product of two vectors
     
     - parameter vectorB: Other vector in the calculation
     */
    func crossProduct(_ vectorB:SCNVector3) -> SCNVector3 {
        
        let computedX = (y * vectorB.z) - (z * vectorB.y)
        let computedY = (z * vectorB.x) - (x * vectorB.z)
        let computedZ = (x * vectorB.y) - (y * vectorB.x)
        
        return SCNVector3(computedX, computedY, computedZ)
    }
    
    /**
     Calculate the angle between two vectors
     
     - parameter vectorB: Other vector in the calculation
     */
    func angleBetweenVectors(_ vectorB:SCNVector3) -> SCNFloat {
        
        //cos(angle) = (A.B)/(|A||B|)
        let cosineAngle = (dotProduct(vectorB) / (magnitude * vectorB.magnitude))
        return SCNFloat(acos(cosineAngle))
    }
    
    func cosOfAngleBetweenVectors(_ vectorB:SCNVector3) -> SCNFloat {
           
           //cos(angle) = (A.B)/(|A||B|)
           let cosineAngle = (dotProduct(vectorB) / (magnitude * vectorB.magnitude))
           return cosineAngle
       }
}
/**
 Add two vectors
 
 - parameter left: Addend 1
 - parameter right: Addend 2
 */
func +(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    
    return SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 Subtract two vectors
 
 - parameter left: Minuend
 - parameter right: Subtrahend
 */
func -(left:SCNVector3, right:SCNVector3) -> SCNVector3 {
    
    return left + (right * -1.0)
}

/**
 Add one vector to another
 
 - parameter left: Vector to change
 - parameter right: Vector to add
 */
func += (left: inout SCNVector3, right:SCNVector3) {
    
    left = SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 Subtract one vector to another
 
 - parameter left: Vector to change
 - parameter right: Vector to subtract
 */
func -= (left: inout SCNVector3, right:SCNVector3) {
    
    left = SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 Multiply a vector times a constant
 
 - parameter vector: Vector to modify
 - parameter constant: Multiplier
 */
func *(vector:SCNVector3, multiplier:SCNFloat) -> SCNVector3 {
    
    return SCNVector3(vector.x * multiplier, vector.y * multiplier, vector.z * multiplier)
}

/**
 Multiply a vector times a constant and update the vector inline
 
 - parameter vector: Vector to modify
 - parameter constant: Multiplier
 */
func *= (vector: inout SCNVector3, multiplier:SCNFloat) {
    
    vector = vector * multiplier
}

func /= (vector: inout SCNVector3, divisor:SCNFloat){
    if vector.x * vector.y * vector.z == 0 {
        vector = SCNVector3Zero
    }
    
    vector = SCNVector3(vector.x / divisor, vector.y / divisor, vector.z / divisor)
}
