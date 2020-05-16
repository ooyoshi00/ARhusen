import UIKit

class MakeHusenController: UIViewController{
    let c_orange = UIColor.rgba(red:255,green:204,blue:102,alpha:1) //オレンジ
    let c_yellow = UIColor.rgba(red:255,green:255,blue:153,alpha:1) //黄色
    let c_pink = UIColor.rgba(red:255,green:204,blue:255,alpha:1) //ピンク
    let c_green = UIColor.rgba(red:153,green:255,blue:0,alpha:1) //緑
    let c_blue = UIColor.rgba(red:204,green:255,blue:255,alpha:1) //水色
    //付箋の色・ラベル
    public var hcolor = UIColor.rgba(red:255,green:204,blue:102,alpha:1)
    public let husen_view = UILabel()
    //テキストフィールド
    public var  textfield = UITextField()
    var textString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //戻るボタン
        let backButton = UIButton(frame: CGRect(x:0,y:100,width: 100,height: 50))
        backButton.setTitle("もどる", for: .normal)
        backButton.backgroundColor = UIColor.blue
        backButton.addTarget(self, action: #selector(MakeHusenController.back(_:)), for: .touchUpInside)
        view.addSubview(backButton)
        //タイトルの生成
        let titleLabel = UILabel()
        titleLabel.frame = CGRect(x:30,y:200,width: UIScreen.main.bounds.size.width-20,height: 38)
        titleLabel.text = "付箋作成画面"
        titleLabel.font = UIFont(name: "Arial Hebrew", size: 30)
        self.view.addSubview(titleLabel)
        //テキストフィールドの生成
        let inputLabel = UILabel()
        inputLabel.frame = CGRect(x:30,y:250,width: UIScreen.main.bounds.size.width-50,height: 38)
        inputLabel.text = "付箋名"
        self.view.addSubview(inputLabel)
        let textfield = UITextField()
        textfield.frame = CGRect(x:30,y:300,width: UIScreen.main.bounds.size.width-100,height: 38)
        textfield.backgroundColor = UIColor(white:0.9,alpha: 1)
        textfield.placeholder = "入力してください"
//        textfield.textAlignment = NSTextAlignment.center
        textfield.keyboardType = .default
        textfield.borderStyle = .roundedRect
        textfield.returnKeyType = .done
        textfield.clearButtonMode = .always
        textfield.addTarget(self, action: #selector(MakeHusenController.textFieldDidChange(_:)),for: UIControl.Event.editingChanged)
        //textfield.addTarget(self, action: #selector(MakeHusenController.textFieldDidChange(_:)),for: UIControl.Event.EditingChanged)
        self.view.addSubview(textfield)
        //カラーピッカーの生成
        let colorLabel = UILabel()
        colorLabel.frame = CGRect(x:30,y:350,width: UIScreen.main.bounds.size.width-50,height: 38)
        colorLabel.text = "色の選択"
        self.view.addSubview(colorLabel)
        // //蛍光色五つを用意
        let color1 = UIButton()
        let color2 = UIButton()
        let color3 = UIButton()
        let color4 = UIButton()
        let color5 = UIButton()
        color1.frame = CGRect(x:30,y:400,width: 100,height: 50)
        color2.frame = CGRect(x:130,y:400,width: 100,height: 50)
        color3.frame = CGRect(x:230,y:400,width: 100,height: 50)
        color4.frame = CGRect(x:330,y:400,width: 100,height: 50)
        color5.frame = CGRect(x:430,y:400,width: 100,height: 50)
        color1.layer.borderWidth = 1.0
        color2.layer.borderWidth = 1.0
        color3.layer.borderWidth = 1.0
        color4.layer.borderWidth = 1.0
        color5.layer.borderWidth = 1.0
        color1.layer.shadowOpacity = 0.5
        color2.layer.shadowOpacity = 0.5
        color3.layer.shadowOpacity = 0.5
        color4.layer.shadowOpacity = 0.5
        color5.layer.shadowOpacity = 0.5
        color1.backgroundColor = c_orange //オレンジ
        color2.backgroundColor = c_yellow //黄色
        color3.backgroundColor = c_pink //ピンク
        color4.backgroundColor = c_green //緑
        color5.backgroundColor = c_blue //水色
        color1.addTarget(self, action: #selector(buttonEvent1(_:)), for: UIControl.Event.touchUpInside)
        color2.addTarget(self, action: #selector(buttonEvent2(_:)), for: UIControl.Event.touchUpInside)
        color3.addTarget(self, action: #selector(buttonEvent3(_:)), for: UIControl.Event.touchUpInside)
        color4.addTarget(self, action: #selector(buttonEvent4(_:)), for: UIControl.Event.touchUpInside)
        color5.addTarget(self, action: #selector(buttonEvent5(_:)), for: UIControl.Event.touchUpInside)
        self.view.addSubview(color1)
        self.view.addSubview(color2)
        self.view.addSubview(color3)
        self.view.addSubview(color4)
        self.view.addSubview(color5)
//        self.navigationController?.popViewController(animated: true)
        
        //付箋作成-途中画面
        //let husen_view = UILabel()
        husen_view.text = "入力してください"
        husen_view.frame = CGRect(x:30,y:500,width: 400,height: 400)
        husen_view.layer.borderWidth = 1.0
        husen_view.layer.shadowOpacity = 0.5
        husen_view.backgroundColor = hcolor
        husen_view.textAlignment = NSTextAlignment.center
        husen_view.font = UIFont(name: "Copperplate-Light", size: 32)
        husen_view.numberOfLines = 0
        self.view.addSubview(husen_view)
        
        //作成ボタン
        let make_husen = UIButton()
        make_husen.frame = CGRect(x:500,y:800,width: 150,height: 100)
        make_husen.layer.borderWidth = 1.0
        make_husen.backgroundColor = UIColor.blue
        make_husen.setTitle("作成", for: .normal)
        make_husen.titleLabel?.font = UIFont(name: "Arial Hebrew", size: 42)
        make_husen.setTitleColor(.white, for: .normal)
        make_husen.layer.cornerRadius = 15
        make_husen.layer.borderColor = UIColor(red: 0.3, green: 0.6, blue: 0.5, alpha: 1).cgColor
        make_husen.addTarget(self, action: #selector(makeHusen(_:)), for: UIControl.Event.touchUpInside)
        self.view.addSubview(make_husen)
        
        //color5.addTarget(self, action: #selector(buttonEvent5(_:)), for: UIControl.Event.touchUpInside)
        //textfield.delegate = self as! UITextFieldDelegate
        //let next2vc = MakeHusenController()
        //self.navigationController?.pushViewController(next2vc, animated: true)
        
//        let goButton = UIButton(frame: CGRect(x: 100,y: 0,width: 100,height:100))
//        goButton.setTitle("Go！", for: .normal)
//        goButton.backgroundColor = UIColor.red
//        goButton.addTarget(self, action: #selector(MakeHusenController.goNext(_:)), for: .touchUpInside)
//        view.addSubview(goButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc func back(_ sender: UIButton) {// selectorで呼び出す場合Swift4からは「@objc」をつける。
        self.dismiss(animated: true, completion: nil)
        print("戻る")
//        _ = self.navigationController?.popViewController(animated: false)
    }
    
    // ボタンが押された時に呼ばれるメソッド
    @objc func buttonEvent1(_ sender: UIButton) {
        //オレンジ
        self.hcolor = c_orange
        self.husen_view.backgroundColor = hcolor
    }
    @objc func buttonEvent2(_ sender: UIButton) {
        //黄色
        self.hcolor = c_yellow
        self.husen_view.backgroundColor = hcolor
    }
    @objc func buttonEvent3(_ sender: UIButton) {
        //ピンク
        self.hcolor = c_pink
        self.husen_view.backgroundColor = hcolor
    }
    @objc func buttonEvent4(_ sender: UIButton) {
        //緑
        self.hcolor = c_green
        self.husen_view.backgroundColor = hcolor
    }
    @objc func buttonEvent5(_ sender: UIButton) {
        //水色
        self.hcolor = c_blue
        self.husen_view.backgroundColor = hcolor
    }
    
    //付箋内のテキスト変更
    @objc func textFieldDidChange(_ sender: UITextField) {
        //print(sender.text)
        self.husen_view.text = sender.text
    }
    
    //UILabelからUIImageに変換
    func getImage(from label:UILabel) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0)
        defer{
            UIGraphicsEndImageContext()
        }
        label.drawHierarchy(in: label.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
    
    //付箋ラベルをUIImageに変換して，画面遷移
    @objc func makeHusen(_ sender: UIButton){
        var myVar = GlobalVar.shared
        myVar.husenImage = getImage(from: husen_view)
        //var image = GlobalVar.husenImage
        if (myVar.husenImage != nil){
            print("作成完了")
            self.dismiss(animated: true, completion: nil)
//            let storyboard = self.storyboard!
//            _ = navigationController?.popViewController(animated: true)
//            let nextvc = ViewController()
//            let naviVC = UINavigationController(rootViewController:nextvc)
//            nextvc.view.backgroundColor = UIColor.white
//            self.present(naviVC,animated: true, completion:nil)
            
            
        } else{
            return
        }
        //imageを持って，viewcontrollerに戻りたい
        
    }
//    @objc func goNext(_ sender: UIButton) {
//        let next2vc = MakeHusenController()
//        next2vc.view.backgroundColor = UIColor.red
//        self.navigationController?.pushViewController(next2vc, animated: true)
//    }
}


extension UIColor {
    class func rgba(red: Int, green: Int, blue: Int, alpha: CGFloat) -> UIColor{
        return UIColor(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }
}
