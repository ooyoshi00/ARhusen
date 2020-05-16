//
//  ViewController.swift
//  purokon2019
//
//  Created by 岡井義宗 on 2019/04/25.
//  Copyright © 2019 岡井義宗. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity
import Foundation
import CoreImage
import SocketIO


class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet weak var sessionInfoView: UIView!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    
    
    //各ボタンのoutlet
    @IBOutlet weak var bdButton: UIButton!
    @IBOutlet weak var bd_album: UIButton!
    @IBOutlet weak var bd_share: UIButton!
    @IBOutlet weak var bd_save: UIButton!
    @IBOutlet weak var bd_restore: UIButton!
    @IBOutlet weak var oppcolor: UIButton!
    
    @IBOutlet weak var bd_husen: UIButton!
    //@IBOutlet var sceneView: ARSCNView!
    var configuration = ARWorldTrackingConfiguration()
    var frame: ARFrame!
    var multipeerSession: MultipeerSession!
    //作成する付箋画像
    //var husenImage:UIImage?
    //配置オブジェクト
    var selectedItem: String?
    //選択オブジェクト(ワンタップ)
    var firstName: String?
    //回転角度
    private var newAngleY :Float = 0.0
    private var newAngleX :Float = 0.0
    private var currentAngleX :Float = 0.0
    private var currentAngleY :Float = 0.0
    private var localTranslatePosition :CGPoint!
    private var initialPosition :CGPoint!
    
    //最新のタップした位置
    var hitTestposition:ARHitTestResult!
    //操作オブジェクト
    var nodeColor:SCNNode!
    // 文字列保存用の変数
    var textFieldString = ""
    //ソケット
    var manager:SocketManager!
    //拡大・縮小の固定
    private var pinchGesture = 0
    //選択オブジェクト
    //private var objectName:String!
    //オブジェクトID
    private var boardID = 0
    private var pictureID = 0
    private var husenID = 0
    //一番上にあるオブジェクトのNode
    private var firstVectorX :Float = 0.0
    private var firstVectorY :Float = 0.0
    private var firstVectorZ :Float = 0.0
    //操作ボタンの切り替え(true:置ける，false:置けない)
    private var oppButton :Bool = false
    //選択オブジェクト名の表示
    @IBOutlet weak var objectLabel: UILabel!
    
    //生成したボードの座標
    //var boardPos:
    enum actionTag: Int{
        case action1 = 0
        case action2 = 1
    }
    
    var mapProvider: MCPeerID?
    var t:String?
    //空間共有トリガー
    var shareTrigger:Bool = false
    //平面トリガー(false:平面，true:垂直面)
    var boardTrigger:Bool = false
    // 拡張子は適当
    let saveURL = "arworldmap.dat"
    //オブジェクトカウンタ
    var count = 0
    //平面アンカー
    var pAnchor:ARPlaneAnchor!
    //位置情報x,y,z
    struct Vector3Entity: Codable {
        let x: Float
        let y: Float
        let z: Float
    }
    
    //4*4行列に対応．rotationとか
    struct Vector4Entity: Codable {
        let x: Float
        let y: Float
        let z: Float
        let w: Float
    }
    
    //送受信：オブジェクトの座標と向き
    struct PlayerEntity: Codable {
        let position: Vector3Entity
        let eulerAngles: Vector3Entity
        let name: String
        let childname: String
    }
    
    //送受信：4*4行列
    struct TransformEntity: Codable {
        let column0: Vector4Entity
        let column1: Vector4Entity
        let column2: Vector4Entity
        let column3: Vector4Entity
    }
    
    //送受信：画像を含めた場合
    struct photo: Codable {
        let name: String
        let id: Int
        let position: Vector3Entity
        let eulerAngles: Vector3Entity
        let image: Data
    }
    
    //送受信：オブジェクト座標を更新する場合
    struct posob: Codable{
        let name: String
        let position: Vector3Entity
        let eulerAngles: Vector3Entity
    }
    
    //ソケット
    //lazy var manager = SocketManager(socketURL: URL(string: "http://localhost:8080")!, config: [.log(true), .compress])
    //let socket = manager.default
    var socket: SocketIOClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
//        initialize()
        // Set the view's delegate
        sceneView.delegate = self
        bdButton.backgroundColor = UIColor.white
        bdButton.isEnabled = true
        oppcolor.backgroundColor = UIColor.white
        oppcolor.isEnabled = true
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //原点の表示
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        //メインビューのタップを検知するようにする
        registerGestureRecognizers()
        bdButton.setImage(UIImage.init(named: "bd_board"), for: UIControl.State.normal)
        bd_album.setImage(UIImage.init(named: "bd_album"), for: UIControl.State.normal)
        bd_share.setImage(UIImage.init(named: "bd_share"), for: UIControl.State.normal)
        bd_save.setImage(UIImage.init(named: "bd_save"), for: UIControl.State.normal)
        bd_restore.setImage(UIImage.init(named: "bd_restore"), for: UIControl.State.normal)
        bd_husen.setImage(UIImage.init(named: "bd_husen"), for: UIControl.State.normal)
        //let nextButton = UIButton(frame: CGRect(x:0,y:0,width: 100,height: 100))
        bd_husen.setTitle("Go!!", for: .normal) //ボタンに表示する文字を指定
        bd_husen.backgroundColor = UIColor.blue
        bd_husen.addTarget(self, action: #selector(ViewController.goNext(_:)), for: .touchUpInside) //タップした時の処理を指定
        //view.addSubview(nextButton) //配置(add)
        let scene = SCNScene()
        
        //ソケット通信関連
        //socket = SocketIOClient(socketURL: SocketURL!, options:[.Log(true), .ForcePolling(true)])
//        manager = SocketManager(socketURL: URL(string: "http://133.68.112.202:8080/")!, config: [.log(true), .compress])
//        self.socket = manager.defaultSocket
//        self.socket.on(clientEvent: .connect) {data, ack in
//            print("socket connected")
//        }
//
//        self.socket.on(clientEvent: .error, callback: {data, ack in
////            print("*** SocketClient Log *** 「on error」")
////            print(data)
//        })
//        self.socket.connect()
//        configuration.planeDetection = .vertical
        // オムニライトを追加
        let lightNode = SCNNode()
        lightNode .light = SCNLight()
        lightNode .light!.type = .omni
        lightNode .position = SCNVector3(x: 0, y: 0, z: 0)
//        scene.rootNode.addChildNode(lightNode )
        sceneView.pointOfView!.addChildNode(lightNode)
        //音声入力部分
        // Set the scene to the view
        //sceneView.scene = scene
    }
    
    //viewが現れる直前の処理．一回しか呼ばれない
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        initialize()
        // 平面、壁面検出の設定（デフォルトはともに検出に設定した）
//        if boardTrigger == false{
//            //平面の検出
//            configuration.planeDetection = [.horizontal,vertical]
//            print("平面検出")
//        }else{
//            //垂直面の検出
//            configuration.planeDetection = [.horizontal,vertical]
//            print("垂直面検出")
//        }
        print("初期化されたたたt")
//        let configuration = ARWorldTrackingConfiguration()
        self.configuration.planeDetection = [.vertical]
        print(configuration.planeDetection)
        // Run the view's session
        sceneView.session.run(self.configuration)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("pause")
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
    
    //トラッキング情報が更新された時
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
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
    
    /// ARSCNiew初期化設定
    func initialize (){
        print("イニシャライズ")
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.configuration.planeDetection = [.vertical]
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
    }
    
    //タップした時にアンカーを追加
//    @objc func tapView(sender: UITapGestureRecognizer) {
//        guard let hitTestResult = sceneView
//            .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
//            .first
//            else { return }
//        let anchor = ARAnchor(name: "box", transform: hitTestResult.worldTransform)
//        sceneView.session.add(anchor: anchor)
//        //        if shareTrigger{
//        //            shareARWorldStatus()
//        //        }
//    }
    
    
    //アンカーが追加された＝平面が検出された時に呼び出される
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("44444444")
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                // 平面ノードを追加する
                if self.pAnchor != nil{
                    return
                }
                //原点の変更
                self.pAnchor = planeAnchor
                node.name = "origin"
//                self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
                let planeNode = self.createPlane(planeAnchor)
//                node.addChildNode(planeNode)
                print("原点の変更")
                //self.planes.append(node)
            }else{
                if let name = anchor.name, name.hasPrefix("board") {
                    //位置
                    //node.position = SCNVector3(thirdColumn.x, thirdColumn.y+0.05, thirdColumn.z)
                    //firstVectorX = thirdColumn.x
                    //firstVectorY = thirdColumn.y+0.05
                    //firstVectorZ = thirdColumn.z
                    // アセットのより、シーンを作成
//                    let scene = SCNScene(named: "art.scnassets/board.scn")
                    let geometry = SCNBox(width: 1.0, height: 0.001, length: 1.0, chamferRadius: 0)
                    let material = SCNMaterial()
                    var myVar = GlobalVar.shared
                    material.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
                    geometry.materials = [material]
                    let node = SCNNode(geometry: geometry)
                    // ノード作成
//                    let nodes=SCNNode()
                    //子ノードにある要素をかたっぱしから変数nodesの子ノードにぶち込む
//                    for var tNode in scene!.rootNode.childNodes{
//                        nodes.addChildNode(tNode)
//                    }
//                    let node=nodes
                    //大きさ
                    node.scale = SCNVector3(0.05,0.05,0.05)
                    //回転
                    node.rotation=SCNVector4(1, 0, 0, 0.5 * Double.pi)
//                    node.rotation=SCNVector4(0, 0, 1, 1.0 * Double.pi)
                    print(name)
                    //名前
                    let peerNames = self.multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
                    //位置
                    let transform = self.hitTestposition.worldTransform
                    let thirdColumn = transform.columns.3
                    node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
                    self.firstVectorX = thirdColumn.x
                    self.firstVectorY = thirdColumn.y
                    self.firstVectorZ = thirdColumn.z
                    //node.name = "board" + String(boardID)
                    //boardID += 1
                    let text = SCNText(string:"board",extrusionDepth: 1)
                    let textNode = SCNNode(geometry: text)
                    //let (min, max) = (textNode.boundingBox)
                    textNode.name = "text"
                    //let x = CGFloat(max.x - min.x)
                    textNode.position = SCNVector3(0,0,0)
                    textNode.scale = SCNVector3(0.1,0.1,0.1)
                    //node.addChildNode(textNode)
                    //print("NODE:",node.name)
                    node.name = "board" + String(self.boardID)
                    self.boardID += 1
                    //sceneView上にオブジェクトを表示
                    self.sceneView.scene.rootNode.addChildNode(node)
                    
                    let node_new = SCNNode()
                    node_new.transform = SCNMatrix4(anchor.transform)
                    //print("送信側anchor：",anchor.transform)
                    print("送信側pos：",node_new.transform)
                    //追加したnodeを他端末に送る
                    let pos = Vector3Entity(x:node_new.position.x,y:node_new.position.y,z:node_new.position.z)
                    //let mat = camera.eulerAngles
                    
                    let euler = node.rotation
                    let mat = Vector3Entity(x:euler.x,y:euler.y,z:euler.z)
                    let entity = PlayerEntity(position: pos,eulerAngles: mat,name:node.name!,childname: node.name!)
                    
                    let data: Data = try! JSONEncoder().encode(entity)
                    // TODO: dataを送る
                    self.multipeerSession.sendToAllPeers(data)
                    
                }else if let name = anchor.name, name.hasPrefix("husen"){
                    print("付箋作成した")
                    let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
                    let material = SCNMaterial()
                    var myVar = GlobalVar.shared
                    material.diffuse.contents = myVar.husenImage
                    geometry.materials = [material]
                    let node = SCNNode(geometry: geometry)
                    //nodeColor = SCNNode(geometry: geometry)
                    //nodeColor.name = "color"
                    //位置
                    //位置
                    let transform = self.hitTestposition.worldTransform
                    let thirdColumn = transform.columns.3
                    node.position = SCNVector3(thirdColumn.x, thirdColumn.y+0.01, thirdColumn.z)
                    self.firstVectorX = thirdColumn.x
                    self.firstVectorY = thirdColumn.y+0.01
                    self.firstVectorZ = thirdColumn.z
                    //大きさ
                    node.scale = SCNVector3(1,1,1)
                    //回転
                    node.rotation=SCNVector4(1, 0, 0, 0.5 * Double.pi)
                    
                    //名前
                    node.name = "husen" + String(self.husenID)
                    self.husenID += 1
                    let peerNames = self.multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
                    //位置
//                    let transform = self.hitTestposition.worldTransform
//                    let thirdColumn = transform.columns.3
//                    node.position = SCNVector3(thirdColumn.x, thirdColumn.y+0.01, thirdColumn.z)
//                    self.firstVectorX = thirdColumn.x
//                    self.firstVectorY = thirdColumn.y+0.05
//                    self.firstVectorZ = thirdColumn.z
                    //node.name = "board" + String(boardID)
                    //boardID += 1
                    // TextFieldから文字を取得
//                    self.textFieldString = self.text_UI.text!
//                    // TextFieldの中身をクリア
//                    self.text_UI.text = ""
                    let text = SCNText(string:self.textFieldString,extrusionDepth: 1)
                    text.materials.first?.diffuse.contents = UIColor.red
                    let textNode = SCNNode(geometry: text)
                    let (min, max) = (textNode.boundingBox)
                    textNode.name = self.textFieldString
                    //let x = CGFloat(max.x - min.x)
                    textNode.position = SCNVector3(-0.005, 0, 0)
                    textNode.scale = SCNVector3(0.001,0.001,0.001)
                    node.addChildNode(textNode)
                    print("NODE:",textNode.name)
//                    node.name = "board" + String(self.boardID)
//                    self.boardID += 1
                    //sceneView上にオブジェクトを表示
                    self.sceneView.scene.rootNode.addChildNode(node)
                    print("これが付箋:",node)
                    let node_new = SCNNode()
                    node_new.transform = SCNMatrix4(anchor.transform)
                    //print("送信側anchor：",anchor.transform)
                    print("送信側pos：",node_new.transform)
                    //追加したnodeを他端末に送る
                    let pos = Vector3Entity(x:node_new.position.x,y:node_new.position.y,z:node_new.position.z)
                    //let mat = camera.eulerAngles
                    
                    let euler = node.rotation
                    let mat = Vector3Entity(x:euler.x,y:euler.y,z:euler.z)
                    let entity = PlayerEntity(position: pos,eulerAngles: mat,name:node.name!,childname: textNode.name!)
                    
                    let data: Data = try! JSONEncoder().encode(entity)
                    // TODO: dataを送る
                    self.multipeerSession.sendToAllPeers(data)
                    
                }
                
            }
        }

    }
    
    //オブジェクトが追加された時に呼び出される
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //Scenekitのnodeの位置が変更された時に呼び出される
        guard let planeAnchor = anchor as? ARAnchor else {
            print("Error: This anchor is not ARPlaneAnchor. [\(#function)]")
            print("anchor:",anchor)
            return
        }
    }
    
    // 平面検出用のオブジェクトの作成
    func createPlane(_ anchor:ARPlaneAnchor) -> SCNNode {
        let node: SCNNode = SCNNode()
        let geometry: SCNBox = SCNBox.init(width: CGFloat(anchor.extent.x), height: 0.01, length: CGFloat(anchor.extent.z), chamferRadius: 0.0)
        geometry.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        node.geometry = geometry
        let position = SCNVector3(anchor.center.x, -0.01, anchor.center.z)
        node.position = position
        return node
    }
    
    //アラート通知
    func alertMessage(title:String,message:String){
        let okText = "ok"
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        let okayButton = UIAlertAction(title: okText, style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(okayButton)
        
        present(alert, animated: true, completion: nil)
    }
    
    //ボード設置のアラート通知
    func BalertMessage(){
        let title = "ボードの設置"
        let message = "ボードを設置しますか"
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        //let okayButton = UIAlertAction(title: okText, style: UIAlertAction.Style.cancel, handler: nil)
        //alert.addAction(okayButton)
        // Defaultボタン
        let defaultAction_1: UIAlertAction = UIAlertAction(title: "壁(垂直面)に設置", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) in
            self.boardTrigger = true
            print("壁(垂直面)に設置")
            //垂直面検出，原点の再設定
            //self.configuration.planeDetection = [.horizontal,vertical]
            // Run the view's session
            //self.sceneView.session.run(self.configuration)
            //self.initialize()
            //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
            //guard let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data!) else { return }
            
            //let configuration = ARWorldTrackingConfiguration()
            //self.configuration.planeDetection = [.horizontal,vertical]
            //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
            //resetTracking:原点がリセット，
            //self.sceneView.session.run(self.configuration, options:[.resetTracking])
            //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
        })
        let defaultAction_2: UIAlertAction = UIAlertAction(title: "机(平面)に設置", style: UIAlertAction.Style.default, handler:{
            (action: UIAlertAction!) in
            self.boardTrigger = false
            print("机(平面)に設置")
            //平面検出，原点の再設定
            //self.initialize()
            //self.configuration.planeDetection = [.horizontal,vertical]
            //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
            //self.sceneView.session.run(self.configuration, options: [.resetTracking])
            //self.configuration.planeDetection = [.horizontal,vertical]
            //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
        })
        alert.addAction(defaultAction_1)
        alert.addAction(defaultAction_2)
        present(alert, animated: true, completion: nil)
    }
    
    //ジェスチャー操作の登録
    func registerGestureRecognizers(){
        //ダブルタップの検出
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        // ダブルタップで反応するように設定します。
        doubleTapGesture.numberOfTapsRequired = 2
        self.sceneView.addGestureRecognizer(doubleTapGesture)
        
        //シングルタップの検出
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        // シングルタップで反応するように設定します。
        tapGestureRecognizer.numberOfTapsRequired = 1
        // シングルタップが失敗した時に、ダブルタップジェスチャーで対応するように設定します。
        tapGestureRecognizer.require(toFail: tapGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //ピンチインで拡大
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        // ロングプレスでノード削除
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressView))
        sceneView.addGestureRecognizer(longPressGesture)
        //回転
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned))
//        self.sceneView.addGestureRecognizer(panGestureRecognizer)
//
        //オブジェクトの移動(パン版)
//        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector
//            (panDrag))
//        self.sceneView.addGestureRecognizer(panGestureRecognizer)
        
        //オブジェクトの移動(ロングタッチ版)
//        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector
//            (longPressed))
//        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        
    }
    
    ///////////////////////////////////
    ///////////////////////////////////ボタン
    //ボード設置ボタン
    @IBAction func boardButton(_ sender: Any) {
        //selectedItem = "10928_Corkboard_v3_L3" //.scnファイル名の指定
        selectedItem = "board" //.scnファイル名の指定
        oppButton = true
        if bdButton.isEnabled{
            bdButton.backgroundColor = UIColor.blue
            oppcolor.backgroundColor = UIColor.white
            oppcolor.isEnabled = true
        }
        else{
            bdButton.backgroundColor = UIColor.white
        }
        bdButton.isEnabled = !bdButton.isEnabled
        //壁・机の選択アラート
        BalertMessage()
        
    }
    
    @IBAction func socketButton(_ sender: Any) {
        self.socket.emit("イベント名", with: ["tako1"])
//        socket.connect()
//
//        CFRunLoopRun()
    }
    //写真追加のボタン
    @IBAction func picsButton(_ sender: Any) {
        selectedItem = "ship" //.scnファイル名の指定
        oppButton = false
        if oppcolor.isEnabled{
            oppcolor.backgroundColor = UIColor.blue
            bdButton.backgroundColor = UIColor.white
            bdButton.isEnabled = true
        }
        else{
            oppcolor.backgroundColor = UIColor.white
        }
        oppcolor.isEnabled = !oppcolor.isEnabled
    }
    
    //写真選択のボタン
    @IBAction func photoButton(_ sender: Any) {
        selectedItem = "picture"
//        if bd_album.isEnabled{
//            bd_album.backgroundColor = UIColor.blue
//            oppcolor.backgroundColor = UIColor.white
//            oppcolor.isEnabled = true
//        }
//        else{
//            bd_album.backgroundColor = UIColor.white
//        }
//        bd_album.isEnabled = !bd_album.isEnabled
        showUIImagePicker()
    }
    
    //空間保存のボタン
    @IBAction func saveButton(_ sender: Any) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            
            if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
                print("データ一覧:",data)
                let path_file_name = dir.appendingPathComponent(self.saveURL)
                print("ファイル名",path_file_name)
                guard ((try? data.write(to: path_file_name)) != nil) else { return }
            }
            
            let title = "空間を保存します"
            let mes = "ok"
            self.alertMessage(title:title, message: mes)
            //self.displayAlert(message: "保存しました")
        }
    }
    
    //空間復元のボタン
    @IBAction func restoreButton(_ sender: Any) {
        var data: Data? = nil
        if let dir = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            
            let path_file_name = dir.appendingPathComponent( self.saveURL )
            print("読み込み",path_file_name)
            do {
                try data = Data(contentsOf: path_file_name)
            } catch {
                print("ファイルが見つかりません")
                return
            }
        }
//        self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
        guard let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data!) else { return }
        
        //let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        configuration.initialWorldMap = worldMap
        //self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        let title = "空間を復元します"
        let mes = "ok"
        alertMessage(title:title, message: mes)
        //self.displayAlert(message: "読み込みました")
    }
    
    //空間共有のボタン
    @IBAction func shareButton(_ sender: Any) {
        //peer端末にワールドマップを送信する
        //offからon: 展開しているWorldMapが近くの端末に共有される
        //onからoff: 展開しているWorldMapがローカルマップになる
        shareTrigger = !shareTrigger
        if shareTrigger{
            shareARWorldStatus()
            self.alertMessage(title: "空間共有開始しました", message: "ok")
            self.mappingStatusLabel.text = "送信ON(自分)"
        }
        else{
            self.alertMessage(title: "空間共有終了しました", message: "ok")
            self.mappingStatusLabel.text = "共有OFF"
        }
        //P2PConnectivity.manager.stop()
    }
    
    ///////////////////////////////////
    ///////////////////////////////////
    
    
    //AR空間を共有する関数
    func shareARWorldStatus(){
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            //print("dataの中：",data)
            self.multipeerSession.sendToAllPeers(data)
        }
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
    }

    
    @IBAction func husen_action(_ sender: Any) {
        selectedItem = "husen"
        oppButton = true
        print("選ばれたのは付箋")
    }
    
    /// - Tag: CheckMappingStatus
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .notAvailable, .limited:
            bd_share.isEnabled = false
        case .extending:
            bd_share.isEnabled = !multipeerSession.connectedPeers.isEmpty
        case .mapped:
            bd_share.isEnabled = !multipeerSession.connectedPeers.isEmpty
        @unknown default:
            print("unknown,frame")
        }
        print("worldStatus:",frame.worldMappingStatus)
        //mappingStatusLabel.text = frame.worldMappingStatus.description
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    
    
 
    
    private func showUIImagePicker() {
        //カメラロールの写真を取得する
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let pickerView = UIImagePickerController()
            pickerView.sourceType = .photoLibrary
            pickerView.delegate = self
            pickerView.modalPresentationStyle = .overFullScreen
            self.present(pickerView, animated: true, completion: nil)
        }
    }
    
    private func setImageToScene(image: UIImage) {
        //画像をNSDataに変換
        let NSimage: NSData = image.pngData()! as NSData
        //NSDataをDataに変換
        let Dimage: Data = Data.init(referencing: NSimage)
        //画像をscene画像に変換する
        if let camera = sceneView.pointOfView {
            print("X:",firstVectorX)
            print("Y:",firstVectorY)
            print("Z:",firstVectorZ)
            let position = SCNVector3(x: firstVectorX, y: firstVectorY+0.01, z: firstVectorZ) // 偏差のベクトルを生成する
            //let convertPosition = camera.convertPosition(position, to: nil)
            //var screenPos = sceneView.projectPoint(convertPosition)
            //画像をNSDataに変換
            let node = createPhotoNode(image, position: position)
            self.sceneView.scene.rootNode.addChildNode(node)
            
            //画像をp2p通信で送信する
            let mat = Vector3Entity(x: node.position.x, y: node.position.y, z: node.position.z)
            let euler = Vector3Entity(x: node.eulerAngles.x, y: node.eulerAngles.y, z: node.eulerAngles.z)
            let entity = photo(name: node.name!, id:pictureID, position: mat, eulerAngles: euler, image: Dimage)
            let data: Data = try! JSONEncoder().encode(entity)
            self.multipeerSession.sendToAllPeers(data)
        }
    }
    
    
    private func createPhotoNode(_ image: UIImage, position: SCNVector3) -> SCNNode {
        //画像のnodeを生成する
        let node = SCNNode()
        let scale: CGFloat = 0.1
        let geometry = SCNBox(width: image.size.width * scale / image.size.height,
                              height: scale,
                              length: 0.00000001,
                              chamferRadius: 0.0)
        geometry.firstMaterial?.diffuse.contents = image
        node.name = "picture" + String(pictureID)
        pictureID += 1
        node.geometry = geometry
        node.position = position
        node.eulerAngles.x = -.pi/2
        //node.rotation = SCNVector4(1, 0, 0, -0.5 * Float.pi)
        
        return node
    }
    
    //付箋作成画面へ遷移
    @objc func goNext(_ sender: UIButton){
//        let next = storyboard!.instantiateViewController(withIdentifier: "nextView")
//        self.present(next,animated: true, completion: nil)
        let nextvc = MakeHusenController()
//        navigationController?.pushViewController(nextvc, animated: true)
//        let naviVC = UINavigationController(rootViewController:nextvc)
        nextvc.view.backgroundColor = UIColor.white
        self.present(nextvc,animated: true, completion:nil)
    }
    
    @objc func longPressView(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let location = sender.location(in: sceneView)
            let hitTest  = sceneView.hitTest(location)
            if let result = hitTest.first  {
                if result.node.name == "cube"
                {
                    result.node.removeFromParentNode();
                }
            }
        }
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        // タップされた位置を取得する
        print(oppButton)
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        
        // タップされた位置のARアンカーを探す
        let hitTestResult = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        // タップされた位置においてあるオブジェクトを探索，なければnil
        let firstNode = sceneView.hitTest(tapLocation, options: nil).first?.node
        
        //最前面にあるオブジェクトのpositionを記録
        //        firstVectorX = Float((firstNode?.position.x)!)
        //        firstVectorY = Float((firstNode?.position.y)!)
        //        firstVectorZ = Float((firstNode?.position.z)!)
        //        print("hitTest:",hitTest)
        //print(type(of: firstNode))
        //if firstNode != nil{print("座標:",firstNode?.position as Any)}
        //let firstNode = hitTestResult.first
        
        //print("名前：",firstNode!.name)
        print("オブジェクト：",firstNode)
        //print(type(of: firstNode?.geometry))
        //.geometry=SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        if firstNode == nil{
            self.objectLabel.text = "なし"
        }else{
            self.objectLabel.text = firstNode!.name
        }
        //self.objectLabel.text = firstNode!.name
        
        //print("TYPE",type(of:firstNode?.position))
        if !hitTestResult.isEmpty && oppButton == true {
            // タップした箇所が取得できていればitemを追加
            guard let hitTestResult = sceneView
                .hitTest(sender.location(in: sceneView), types: [.existingPlaneUsingGeometry, .estimatedHorizontalPlane])
                .first
                else { return }
            hitTestposition = hitTestResult
            print("ヒットテスト")
            let anchor = ARAnchor(name: selectedItem!, transform: hitTestResult.worldTransform)
            sceneView.session.add(anchor: anchor)
            //self.addItem(hitTestResult: hitTest.first!)
            //タップしたオブジェクトのみ色を変更
            //firstNode!.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            //タップ時にオブジェクトがあれば実行
            //sceneView.showsStatistics = false
            oppButton = false
        }
        else{
            //タップ時にオブジェクトがなければ実行
            self.firstName = firstNode?.name
            //print("オブジェクト：",firstNode)
            sceneView.showsStatistics = true
        }
    }
    
    
    
    //ダブルタップした時の処理
    @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
        // ダブルタップされた時の処理を記述してください。
        print("ダブルタップ")
        pinchGesture += 1
    }
    
    //ピンチイン，ピンチアウトで拡大・縮小
    @objc func pinched(recognizer: UIPinchGestureRecognizer) {
        //print("pinches")
        let peerNames = self.multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
        let b_name = ":board:" + String(self.count-1)
        //print("判定：",oppButton)
        print("オブジェクト名：",peerNames)
        if recognizer.state == .changed && oppButton == false{
            print("pinches")
            var pg = pinchGesture % 2
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                print("b:",b_name)
                print("node:",node.name)
                if node.name == "board"+String(boardID-1) && pg == 0{
                    print("board_pinch")
                    let pinchScaleX = Float(recognizer.scale) * node.scale.x
                    //let pinchScaleY = Float(recognizer.scale) * node.scale.y
                    let pinchScaleZ = Float(recognizer.scale) * node.scale.z
                    
                    node.scale = SCNVector3Make(pinchScaleX,node.scale.y,pinchScaleZ)
                    recognizer.scale = 1
                    print("board")
                }
                else if node.name == "picture"+String(pictureID-1) && pg == 0{
                    print("picture")
                    let pinchScaleX = Float(recognizer.scale) * node.scale.x
                    let pinchScaleY = Float(recognizer.scale) * node.scale.y
                    let pinchScaleZ = Float(recognizer.scale) * node.scale.z
                    
                    node.scale = SCNVector3Make(pinchScaleX,pinchScaleY,pinchScaleZ)
                    recognizer.scale = 1
                    //print(type(of: node.name))
                }
                //sceneView.scene.rootNode.addChildNode(node)
            }
            
        }
    }
    
//    //角度
//    @objc func panned(recognizer: UIPanGestureRecognizer) {
//        switch recognizer.state {
//        case .changed:
//            guard let pannedView = recognizer.view as? ARSCNView else { return }
//            let translation = recognizer.translation(in: pannedView)
//
//            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
//                if node.name == "board" {
//                    self.newAngleX = Float(translation.y) * (Float)(Double.pi)/180
//                    self.newAngleX += self.currentAngleX
//                    self.newAngleY = Float(translation.x) * (Float)(Double.pi)/180
//                    self.newAngleY += self.currentAngleY
//                    node.eulerAngles.x = self.newAngleX
//                    node.eulerAngles.y = self.newAngleY
//                }
//            }
//
//        case .ended:
//            self.currentAngleX = self.newAngleX
//            self.currentAngleY = self.newAngleY
//        default:
//            break
//        }
//    }
    
    
    //パンでオブジェクトの移動
    @objc func panDrag(recognizer: UIPanGestureRecognizer) {
        //guard let panView = recognizer.view as? ARSCNView else { return }
        guard recognizer.view != nil else {return}
        //let piece = gestureRecognizer.view!
        let piece = recognizer.view! //操作可能な範囲のview(端末画面)
        let translation = recognizer.translation(in: piece.superview) //画面上でどこをタッチしたか
        //var pg = pinchGesture % 2
        //scene内の全ノードに対して処理
        self.sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
            //print("タイプ：",type(of: node.name))
            let tName = node.name
            if tName != nil && tName==firstName{
                //print("パンパン")
                 //カメラからオブジェクトに対する角度
                //print("角度:",angle)
                //node.eulerAngles = camera!.eulerAngles
//                let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
//                let material = SCNMaterial()
//                material.diffuse.contents = UIColor.yellow
//                geometry.materials = [material]
//                nodeColor = SCNNode(geometry: geometry)
//                nodeColor.name = "color"
                if recognizer.state == .began {
                    // Save the view's original position. 
                    self.initialPosition = translation //最初にタッチした場所(画面)を保持
                }
                // Update the position for the .began, .changed, and .ended states
                if recognizer.state != .cancelled {
                    // Add the X and Y translation to the view's original position.
                    guard let camera = self.sceneView.pointOfView else{
                        return
                    }//端末の座標
                    var angle = acos(camera.position.z/(sqrt(pow(camera.position.x,2.0) + pow(camera.position.z,2.0))))
                    if camera.position.x < 0.0{
                        angle = 2 * Float.pi - angle
                    }
                    let posi = myconvPosition(node.position, angle: angle)
                    print("角度：",(angle*180)/Float.pi)
                    print("translation:",translation)
                    print("node.position:",posi)
                    
                    //オブジェクト座標の移動，float数値は移動の度合(小さいほど移動単位が小さくなる)
                    let newCenter = myconvPosition(SCNVector3(x:posi.x + Float(translation.x)*0.00003,
                                                              y:posi.y,
                                                              z:posi.z + Float(translation.y)*0.00003),angle:-angle)
                    //print(translation)
                    node.position = newCenter
                    self.initialPosition=translation
                }
                else {
                    // On cancellation, return the piece to its original location.
                    piece.center = initialPosition
                }
            }
        }
    }
    
    //
    private func myconvPosition(_ sender:SCNVector3,angle:Float)->SCNVector3{
        let pos = SCNVector3(sender.x * cos(angle) - sender.z*sin(angle),sender.y,sender.x*sin(angle)+sender.z*cos(angle))
        return pos
    }
    //ロングタッチ,オブジェクトの移動
    @objc func longPressed(recognizer: UILongPressGestureRecognizer) {
        guard let longPressedView = recognizer.view as? ARSCNView else { return }
        let touch = recognizer.location(in: longPressedView)
        //var pg = pinchGesture % 2
        //scene内の全ノードに対して処理
        self.sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
            //print("タイプ：",type(of: node.name))
            let tName = node.name
            if tName != nil && tName==firstName && oppButton == false{
                print("ロングタッチ")
                let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.yellow
                geometry.materials = [material]
                nodeColor = SCNNode(geometry: geometry)
                nodeColor.name = "color"
                switch recognizer.state {
                case .began:
                    localTranslatePosition = touch
                    self.objectLabel.text = "drag"
                    nodeColor.position = SCNVector3(CGFloat(node.position.x),CGFloat(node.position.y),CGFloat(node.position.z))
                    self.sceneView.scene.rootNode.addChildNode(nodeColor)
                case .changed:
                    let deltaX = Float(touch.x - self.localTranslatePosition.x)/1400
                    let deltaY = Float(touch.y - self.localTranslatePosition.y)/1400
                    if (node.name?.contains("picture"))!{
                        node.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
                        nodeColor.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
                    }else{
                        node.localTranslate(by: SCNVector3(deltaX,0.0,deltaY))
                        nodeColor.localTranslate(by: SCNVector3(deltaX,0.0,deltaY))
                    }
//                    node.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
//                    nodeColor.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
                    self.localTranslatePosition = touch
                    
//                    //オブジェクト座標をリアルタイム共有
//                    let mat = Vector3Entity(x: node.position.x, y: node.position.y, z: node.position.z)
//                    let euler = Vector3Entity(x: node.eulerAngles.x, y: node.eulerAngles.y, z: node.eulerAngles.z)
//                    let entity = posob(name: tName!, position: mat, eulerAngles: euler)
//                    let data: Data = try! JSONEncoder().encode(entity)
//                    self.multipeerSession.sendToAllPeers(data)
                    
                case .ended:
                    let n = self.sceneView.scene.rootNode.childNode(withName: nodeColor.name!, recursively: true)
                    n!.removeFromParentNode()
                    self.objectLabel.text = ""
                    //オブジェクト座標をリアルタイム共有
                    let mat = Vector3Entity(x: node.position.x, y: node.position.y, z: node.position.z)
                    let euler = Vector3Entity(x: node.eulerAngles.x, y: node.eulerAngles.y, z: node.eulerAngles.z)
                    let entity = posob(name: tName!, position: mat, eulerAngles: euler)
                    let data: Data = try! JSONEncoder().encode(entity)
                    self.multipeerSession.sendToAllPeers(data)
                    break
                default:
                    print("しゅうりょう")
                    break
                }
            }
        }
    }
    
    /// - Tag: ReceiveData
    //ワールドマップの受け取り処理
    func receivedData(_ data: Data, from peer: MCPeerID) {
        DispatchQueue.main.async {
            self.t = self.mappingStatusLabel.text
        }
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                //configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = [.vertical]
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                print("panchor:",pAnchor)
//                self.sceneView.session.setWorldOrigin(relativeTransform: self.pAnchor.transform)
                // Remember who provided the map for showing UI feedback.
                mapProvider = peer
                //メインスレッドでステータスの変更
                DispatchQueue.main.async{
                    self.mappingStatusLabel.text = "共有ON(他人)"
                }
            }
            else
                if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                    // Add anchor to the session, ARSCNView delegate adds visible content.
                    sceneView.session.add(anchor: anchor)
                }
                else {
                    print("unknown data recieved from \(peer)")
            }
        }catch{}
        
        if t == "共有ON(他人)"{
            print("他人")
            do {
                let decoder: JSONDecoder = JSONDecoder()
                print("jsonを取得")
                //let PLentity: PlayerEntity = try decoder.decode(PlayerEntity.self, from: data)
                let PIentity: photo = try decoder.decode(photo.self, from: data)
                //print("PL:",PLentity)
                print("PI:",PIentity)
                // これを使って相手のデバイスを空間上で再現する
                var object = self.sceneView.scene.rootNode.childNode(withName: PIentity.name, recursively: true)
                if object == nil{  //ローカルに共有オブジェクトが存在しない場合
                    if((PIentity.name).contains("picture")){
                        print("シャシーーーーーん")
                        object = SCNNode()
                        //self.sceneView.scene.rootNode.addChildNode(object!)
                        let position = SCNVector3(PIentity.position.x, PIentity.position.y, PIentity.position.z)
                        let NSimage = NSData.init(data: PIentity.image)
                        let image: UIImage? = UIImage(data: NSimage as Data)
                        var object = createPhotoNode(image!, position: position)
                        print("画像：",image)
                        print("画像大きさ：",object.scale)
                        //let positions = PIentity.position
                        let eulerAngles = PIentity.eulerAngles
                        object.name = PIentity.name
                        
                        object.position = position
                        print("object:",object)
                        object.eulerAngles = SCNVector3(eulerAngles.x,eulerAngles.y,eulerAngles.z)
                        self.sceneView.scene.rootNode.addChildNode(object)
                        print("名前",object.name)
                        print("位置",position)
                        pictureID = PIentity.id
                        //setImageToScene(image:image!)
                    }
                }
            } catch {
            }
            
            do{//ローカルに共有オブジェクトが既に存在している場合
                print("写真の移動")
                let decoder: JSONDecoder = JSONDecoder()
                print("jsonを取得")
                //let PLentity: PlayerEntity = try decoder.decode(PlayerEntity.self, from: data)
                let PIentity: posob = try decoder.decode(posob.self, from: data)
                //self.sceneView.scene.rootNode.addChildNode(object!)
                let object = self.sceneView.scene.rootNode.childNode(withName: PIentity.name, recursively: true)
                let position = SCNVector3(PIentity.position.x, PIentity.position.y, PIentity.position.z)
                //let NSimage = NSData.init(data: PIentity.image)
                let eulerAngles = PIentity.eulerAngles
                self.sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
                    //print("タイプ：",type(of: node.name))
                    if PIentity.name == node.name {
                        print("ロングタッチ受信")
                        let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.blue
                        geometry.materials = [material]
                        nodeColor = SCNNode(geometry: geometry)
                        nodeColor.name = "color"
                        
                        let deltaX = Float(position.x)
                        let deltaY = Float(position.y)
                        let deltaZ = Float(position.z)
                        
                        node.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
                        nodeColor.localTranslate(by: SCNVector3(deltaX,-deltaY,0.0))
                        print("受信データ：",node)
                        //self.localTranslatePosition = touch
                    }
                }
                //setImageToScene(image:image!)
            }catch{
                print("移動エラー")
            }
            
            do {//ボードを追加した時
                let decoder: JSONDecoder = JSONDecoder()
                print("jsonを取得")
                let PLentity: PlayerEntity = try decoder.decode(PlayerEntity.self, from: data)
                //let PIentity: photo = try decoder.decode(photo.self, from: data)
                print("PL:",PLentity)
                //print("PI:",PIentity)
                // これを使って相手のデバイスを空間上で再現する
                var object = self.sceneView.scene.rootNode.childNode(withName: PLentity.name, recursively: true)
                if object == nil{
                    if((PLentity.name).contains("board")){
                        print("ボーーーーーーーど")
                        let scene = SCNScene(named: "art.scnassets/board.scn")
                        // ノード作成
                        let nodes=SCNNode()
                        //子ノードにある要素をかたっぱしから変数nodesの子ノードにぶち込む
                        for var tNode in scene!.rootNode.childNodes{
                            nodes.addChildNode(tNode)
                        }
                        object=nodes
                        
                        //                        let geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
                        //                        object = SCNNode(geometry: geometry)
                        //                        let material = SCNMaterial()
                        //                        material.diffuse.contents = UIColor.red
                        //                        geometry.materials = [material]
                        //                        node.position = SCNVector3(position.x,position.y,position.z)
                        //                        node.eulerAngles = SCNVector3(eulerAngles.x,eulerAngles.y,eulerAngles.z)
                        //print("nodeを表示")
                        object!.scale = SCNVector3(0.05,0.05,0.05)
                        self.sceneView.scene.rootNode.addChildNode(object!)
                        let position = PLentity.position
                        let eulerAngles = PLentity.eulerAngles
                        object!.position = SCNVector3(position.x,position.y,position.z)
                        object!.eulerAngles = SCNVector3(eulerAngles.x,eulerAngles.y,eulerAngles.z)
                        print("位置",PLentity.position)
                    }else if((PLentity.name).contains("husen")){
                        print("付箋デーーーす")
                        //let scene = SCNScene(named: "art.scnassets/board.scn")
                        // ノード作成
                        let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.darkGray
                        geometry.materials = [material]
                        let node_h = SCNNode(geometry: geometry)
                        node_h.name = PLentity.name
                        let text = SCNText(string:PLentity.childname,extrusionDepth: 1)
                        text.materials.first?.diffuse.contents = UIColor.red
                        let textNode = SCNNode(geometry: text)
                        //let (min, max) = (textNode.boundingBox)
                        textNode.name = PLentity.childname
                        //let x = CGFloat(max.x - min.x)
                        textNode.position = SCNVector3(-0.005, 0, 0)
                        textNode.scale = SCNVector3(0.001,0.001,0.001)
                        node_h.addChildNode(textNode)
                        object = node_h
                        object!.scale = SCNVector3(1,1,1)
                        self.sceneView.scene.rootNode.addChildNode(object!)
                        let position = PLentity.position
                        let eulerAngles = PLentity.eulerAngles
                        object!.position = SCNVector3(position.x,position.y,position.z)
                        object!.eulerAngles = SCNVector3(eulerAngles.x,eulerAngles.y,eulerAngles.z)
                        print("位置",PLentity.position)
                    }
                }
                
            } catch {
                
            }
            do{//ローカルに共有オブジェクト(付箋)が既に存在している場合
                print("付箋の移動")
                let decoder: JSONDecoder = JSONDecoder()
                print("jsonを取得")
                //let PLentity: PlayerEntity = try decoder.decode(PlayerEntity.self, from: data)
                let PLentity: posob = try decoder.decode(posob.self, from: data)
                //self.sceneView.scene.rootNode.addChildNode(object!)
                let object = self.sceneView.scene.rootNode.childNode(withName: PLentity.name, recursively: true)
                let position = SCNVector3(PLentity.position.x, PLentity.position.y, PLentity.position.z)
                //let NSimage = NSData.init(data: PIentity.image)
                let eulerAngles = PLentity.eulerAngles
                self.sceneView.scene.rootNode.enumerateChildNodes {(node, _) in
                    //print("タイプ：",type(of: node.name))
                    if PLentity.name == node.name {
                        print("ロングタッチ受信")
                        let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
                        let material = SCNMaterial()
                        material.diffuse.contents = UIColor.blue
                        geometry.materials = [material]
                        nodeColor = SCNNode(geometry: geometry)
                        nodeColor.name = "color"
                        
                        let deltaX = Float(position.x)
                        let deltaY = Float(position.y)
                        let deltaZ = Float(position.z)
                        
                        node.localTranslate(by: SCNVector3(deltaX,0.0,deltaZ))
                        nodeColor.localTranslate(by: SCNVector3(deltaX,0.0,deltaZ))
                        print("受信データ：",node)
                        //self.localTranslatePosition = touch
                    }
                }
                //setImageToScene(image:image!)
            }catch{
                print("移動エラー")
            }
            
        }
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        //        } catch {
        //            print("can't decode data recieved from \(peer)")
        //        }
    }
    
    
    
    //セッション状態のラベル更新
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            //message = "Move around to map the environment, or wait to join a shared session."
            message = "環境をマップするために探索中，もしくは共有セッションの待機中"
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            //message = "Connected with \(peerNames)."
            message = "\(peerNames)に接続中"
            
        case .notAvailable:
            //message = "Tracking unavailable."
            message = "トラッキングできません"
            
        case .limited(.excessiveMotion):
            //message = "Tracking limited - Move the device more slowly."
            message = "トラッキング制限 - デバイスをもっとゆっくり動かしてください"
            
        case .limited(.insufficientFeatures):
            //message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            message = "トラッキング制限 - 表面の細部が見える部分にデバイスを向ける、または照明条件を改善してください"
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            //message = "Received map from \(mapProvider!.displayName)."
            message = "\(mapProvider!.displayName)からマップを受け取りました"
            
        case .limited(.relocalizing):
            //message = "Resuming session — move to where you were when the session was interrupted."
            message = "セッションの再開 - セッションが中断されたときの場所に移動します"
            
        case .limited(.initializing):
            //message = "Initializing AR session."
            message = "セッションを初期化中"
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        print("status::",message)
        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }
    /// アイテム配置メソッド
//    func addItem(hitTestResult: ARHitTestResult) {
//        if let selectedItem = self.selectedItem {
//
////            // アセットのより、シーンを作成
////            let scene = SCNScene(named: "art.scnassets/\(selectedItem).scn")
////            //print(scene)
////            // ノード作成
////            let nodes=SCNNode()
////            //子ノードにある要素をかたっぱしから変数nodesの子ノードにぶち込む
////            for var tNode in scene!.rootNode.childNodes{
////                nodes.addChildNode(tNode)
////            }
////            let node=nodes
////            if let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false)){
//            // 現実世界の座標を取得
//            let transform = hitTestResult.worldTransform
//            let thirdColumn = transform.columns.3
//
//            // アイテムの配置
//            if selectedItem == "board"{
//                // アセットのより、シーンを作成
//                let scene = SCNScene(named: "art.scnassets/\(selectedItem).scn")
//                // ノード作成
//                let nodes=SCNNode()
//                //子ノードにある要素をかたっぱしから変数nodesの子ノードにぶち込む
//                for var tNode in scene!.rootNode.childNodes{
//                    nodes.addChildNode(tNode)
//                }
//                let node=nodes
//                //位置
//                node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
//                firstVectorX = thirdColumn.x
//                firstVectorY = thirdColumn.y
//                firstVectorZ = thirdColumn.z
//                //大きさ
//                node.scale = SCNVector3(0.01,0.01,0.01)
//                //名前
//                let peerNames = self.multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//                node.name = peerNames + ":board:" + String(self.count)
//                //node.name = "board" + String(boardID)
//                boardID += 1
//                let text = SCNText(string:"board",extrusionDepth: 1)
//                let textNode = SCNNode(geometry: text)
//                let (min, max) = (textNode.boundingBox)
//                textNode.name = "text"
//                let x = CGFloat(max.x - min.x)
//                textNode.position = SCNVector3(0,0,0)
//                textNode.scale = SCNVector3(0.1,0.1,0.1)
//                node.addChildNode(textNode)
//                //print("NODE:",node.name)
//                //sceneView上にオブジェクトを表示
//                self.sceneView.scene.rootNode.addChildNode(node)
//
//
//            }
//            else if selectedItem == "ship"{
//                //node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
//                guard let currentFrame = sceneView.session.currentFrame else { return  }
//
//                let viewWidth  = sceneView.bounds.width
//                let viewHeight = sceneView.bounds.height
//                let imagePlane = SCNPlane(width: viewWidth/1000, height: viewHeight/1000)
//                imagePlane.firstMaterial?.diffuse.contents = sceneView.snapshot()
//                imagePlane.firstMaterial?.lightingModel = .constant
//
//                let planeNode = SCNNode(geometry: imagePlane)
//                //画像の回転
//                planeNode.rotation = SCNVector4(1, 0, 0, -0.5 * Float.pi)
//                //sceneView.scene.rootNode.addChildNode(planeNode)
//            }
//            else if selectedItem == "husen"{
//                // アセットのより、シーンを作成
//                //let scene = SCNScene(named: "art.scnassets/\(selectedItem).scn")
//                // ノード作成
//                //let nodes=SCNNode()
//                //子ノードにある要素をかたっぱしから変数nodesの子ノードにぶち込む
////                for var tNode in scene!.rootNode.childNodes{
////                    nodes.addChildNode(tNode)
////                }
//                //let node=nodes
//
//
//                let geometry = SCNBox(width: 0.1, height: 0.001, length: 0.1, chamferRadius: 0)
//                let material = SCNMaterial()
//                material.diffuse.contents = UIColor.darkGray
//                geometry.materials = [material]
//                let node = SCNNode(geometry: geometry)
//                //nodeColor = SCNNode(geometry: geometry)
//                //nodeColor.name = "color"
//                //位置
//                node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
//                firstVectorX = thirdColumn.x
//                firstVectorY = thirdColumn.y
//                firstVectorZ = thirdColumn.z
//                //大きさ
//                node.scale = SCNVector3(1,1,1)
//                //名前
//                let peerNames = self.multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
//                node.name = peerNames + ":husen:" + String(self.count)
//                //node.name = "board" + String(boardID)
//                //boardID += 1
////                let text = SCNText(string:"board",extrusionDepth: 1)
////                let textNode = SCNNode(geometry: text)
////                let (min, max) = (textNode.boundingBox)
////                textNode.name = "text"
////                let x = CGFloat(max.x - min.x)
////                textNode.position = SCNVector3(0,0,0)
////                textNode.scale = SCNVector3(0.1,0.1,0.1)
////                node.addChildNode(textNode)
//                print("NODE:",node.name)
//                //sceneView上にオブジェクトを表示
//                self.sceneView.scene.rootNode.addChildNode(node)
//            }
//            //node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
//            //大きさ
////            node.scale = SCNVector3(0.1,0.1,0.1)
////            //sceneView上にオブジェクトを表示
////            self.sceneView.scene.rootNode.addChildNode(node)
//
//
//            // 現実世界の座標を取得
////            let transform = hitTestResult.worldTransform
////            let thirdColumn = transform.columns.3
//
//            // アイテムの配置
////            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
////            self.sceneView.scene.rootNode.addChildNode(node)
//        }
//    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            setImageToScene(image: image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


