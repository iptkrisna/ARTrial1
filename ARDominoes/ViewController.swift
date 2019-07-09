//
//  ViewController.swift
//  ARDominoes
//
//  Created by I Putu Krisna on 09/07/19.
//  Copyright © 2019 I Putu Krisna. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var detectedPlanes: [String : SCNNode] = [:]
    var dominoes: [SCNNode] = []
    var previousDominoPosition: SCNVector3?
    let dominoColors: [UIColor] = [.red, .blue, .green, .yellow, .orange, .cyan, .magenta, .purple]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(screenPanned))
        sceneView.addGestureRecognizer(panGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // 2
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        // 3
        planeNode.opacity = 0.3
        // 4
        planeNode.rotation = SCNVector4Make(1, 0, 0, -Float.pi / 2.0)
        node.addChildNode(planeNode)
        // 5
        detectedPlanes[planeAnchor.identifier.uuidString] = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        // 2
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x,
                                            planeAnchor.center.y,
                                            planeAnchor.center.z)
        
        planeNode.opacity = 0.0
        
    }
    
    @objc func screenPanned(gesture: UIPanGestureRecognizer) {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        let location = gesture.location(in: sceneView)
        guard let hitTestResult = sceneView.hitTest(location, types: .existingPlane).first else { return }
        // 1
        guard let previousPosition = previousDominoPosition else {
            self.previousDominoPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                                         hitTestResult.worldTransform.columns.3.y,
                                                         hitTestResult.worldTransform.columns.3.z)
            return
        }
        // 2
        let currentPosition = SCNVector3Make(hitTestResult.worldTransform.columns.3.x,
                                             hitTestResult.worldTransform.columns.3.y,
                                             hitTestResult.worldTransform.columns.3.z)
        // 3
        let minimumDistanceBetweenDominoes: Float = 0.03
        let distance = distanceBetween(point1: previousPosition, andPoint2: currentPosition)
        if distance >= minimumDistanceBetweenDominoes {
            let dominoGeometry = SCNBox(width: 0.007, height: 0.06, length: 0.03, chamferRadius: 0.0)
            dominoGeometry.firstMaterial?.diffuse.contents = dominoColors.randomElement()
            let dominoNode = SCNNode(geometry: dominoGeometry)
            dominoNode.position = SCNVector3Make(currentPosition.x,
                                                 currentPosition.y + 0.03,
                                                 currentPosition.z)
            // 1
            var currentAngle: Float = pointPairToBearingDegrees(startingPoint: CGPoint(x: CGFloat(currentPosition.x), y: CGFloat(currentPosition.z)), secondPoint: CGPoint(x: CGFloat(previousPosition.x), y: CGFloat(previousPosition.z)))
            // 2
            currentAngle *= .pi / 180
            // 3
            dominoNode.rotation = SCNVector4Make(0, 1, 0, -currentAngle)
            sceneView.scene.rootNode.addChildNode(dominoNode)
            dominoes.append(dominoNode)
            // 4
            self.previousDominoPosition = currentPosition
        }
    }
    
    func distanceBetween(point1: SCNVector3, andPoint2 point2: SCNVector3) -> Float {
        return hypotf(Float(point1.x - point2.x), Float(point1.z - point2.z))
    }
    
    func pointPairToBearingDegrees(startingPoint: CGPoint, secondPoint endingPoint: CGPoint) -> Float{
        let originPoint: CGPoint = CGPoint(x: startingPoint.x - endingPoint.x, y: startingPoint.y - endingPoint.y)
        let bearingRadians = atan2f(Float(originPoint.y), Float(originPoint.x))
        let bearingDegrees = bearingRadians * (180.0 / Float.pi)
        return bearingDegrees
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
