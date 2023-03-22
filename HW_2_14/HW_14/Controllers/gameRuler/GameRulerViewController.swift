
import UIKit
import SceneKit
import ARKit

class GameRulerViewController: UIViewController, ARSCNViewDelegate { // ARSCNViewDelegate - для использования метода hitTest (объекта ARSCNVeiw)
    
    var dotNodes = [SCNNode]()
    private var line = SCNNode()
    
    var dist: NSString = ""
    var textNode = SCNNode()
    
    @IBOutlet weak var distanceOld: UILabel!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBAction func closeButton(_ sender: Any) {
        Score.shared.scoreRuler = "\(dist) см"
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var view3dOutlet: UIButton! { didSet {
        let imgName = UIImage(named: "3d-fill-100.png")!
        view3dOutlet.setImage(imgName, for: .normal)
    }}
    
    // MARK: - переключатель 3D режимов
    var flag3d = true // 3D режим результата
    
    @IBAction func view3dButton(_ sender: UIButton) { // переключение вида результата с 3D вида на 2D
        flag3d = !flag3d
        print(flag3d)
        setButtonImage()
    }
    
    func setButtonImage() { // смена иконки кнопки
        let img = flag3d ? "3d-fill-100" : "3d-100"
        let imgName = UIImage(named: "\(img).png")!
        view3dOutlet.setImage(imgName, for: .normal)
    }
    
    // MARK: - переключатель режимов "до точки", "между точками"
    var flagMode = true
    
    @IBOutlet weak var switchModeOutlet: UISegmentedControl!
    
    @IBAction func switchModePress(_ sender: UISegmentedControl) {
        switch switchModeOutlet.selectedSegmentIndex
        {
        case 0:
            flagMode = !flagMode
        case 1:
            flagMode = !flagMode
        default:
            break;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self // делегат ARSCNViewDelegate
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints // ключевые точки, которые находит ARKit (желтенькие)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()

        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
  
        sceneView.session.pause()
    }
    
    //MARK: - прикосновение к экрану
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // реализация прикосновения к экрану
        if let touchLocation = touches.first?.location(in: sceneView) {
            let hitTestResults = sceneView.hitTest(touchLocation, types: .featurePoint) // hitTest - Этот метод на основе данных ARKit определяет все распознанные объекты и поверхности, пересекающие луч, направленный от камеры, и возвращает в порядке удаления от девайса полученные данные о пересечении.
            if let hitResult = hitTestResults.first {
                addDot(at: hitResult)
            }
        }
    }
    
    //MARK: - функция с математикой, достает направление нашего просмотра (векторы направления в 3д пространстве)
    func getUserVector() -> (SCNVector3) { // (direction, position) направление, положение
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // матрица преобразования 4x4, описывающая камеру в мировом пространстве
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // расположение камеры в пространстве
            return (pos)
        }
        return (SCNVector3(0, 0, -0.2))
    }
    
    // MARK: -  ставим точку или точки
    func addDot(at hitResult: ARHitTestResult){
        
        if dotNodes.count >= 2 {
            for dot in dotNodes {
                dot.removeFromParentNode()
                line.removeFromParentNode()
            }
            dotNodes = [SCNNode]()
        }
        
        let dotGeometry = SCNSphere(radius: 0.005)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        dotGeometry.materials = [material]

        let dotNode = SCNNode(geometry: dotGeometry)
        
        if flagMode == true { // точки старта в режиме "одна точка"
            let pos = self.getUserVector() // узнаем положение и направление пользователей
            let dotNodeStart = SCNNode() // точка камеры или старта
            dotNodeStart.position = pos
            sceneView.scene.rootNode.addChildNode(dotNodeStart)
            dotNodes.append(dotNodeStart)
        }
        // точка старта и финиша в режиме "две точки"
        dotNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(dotNode)
        dotNodes.append(dotNode)
        
        // обработка узла текста в зависимости от количества точек
        if dotNodes.count == 2 { // точек две - пошел расчет
            calculate()
            
            if flagMode != true {
                // рисуем линию (толщину задать невозможно = glLineWidth убрали из метала ios10 и ничем не заменили - технически не возможно (надо рисовать страшный цилиндр)
                let startNode = dotNodes[0].position
                let endNode = dotNodes[1].position
                
                line.geometry = lineFrom(vector: startNode, toVector: endNode)
                line.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                line.geometry?.firstMaterial?.isDoubleSided = true
                
                sceneView.scene.rootNode.addChildNode(line)
            }
        } else if dotNodes.count == 1 { // точек одна из двух - удаляем узел с текстом (чтобы не висело старое значение)
            textNode.removeFromParentNode()
            line.removeFromParentNode()
        }
    }
    
    // MARK: - рисуем линию
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry { // функцию, которая будет возвращать геометрию линии (по ней SceneKit поймет, как и где рисовать SCNNode)
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
        
    }
    
    // MARK: - калькулятор расстояния
    func calculate(){
        let start = dotNodes[0]
        let end = dotNodes[1]
        
        let distance = sqrt(
            pow(end.position.x - start.position.x, 2) +
            pow(end.position.y - start.position.y, 2) +
            pow(end.position.z - start.position.z, 2)
        )
        
        dist = NSString(format: "%.0f", (distance * 100))
        
    // доделать тут заменить на выбор функций которые обносвляют 3д и 2д надпись и стирают ненужные написи
        flag3d == true ?
        activating3dMode() : activating2dMode()
    

        func activating3dMode() { // flag3d = true
            updateText(text: "\(dist) см", atPosition: end.position)
            distanceOld.text = ""
        }
        
        func activating2dMode() { //  flag3d = false
                distanceOld.text = "\(dist) см"
            updateText(text: "", atPosition: end.position)
            
        }
    }
    
    // MARK: - визуализация узла с текстовыми данными расстояния
    func updateText(text: String, atPosition position: SCNVector3) {
        
        textNode.removeFromParentNode()
        
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)

        // в режиме одна точка - розовый результат, в режиме 2 точки голубой
        flagMode == true ? (textGeometry.firstMaterial?.diffuse.contents = UIColor.systemPink) : (textGeometry.firstMaterial?.diffuse.contents = UIColor.systemBlue)
        
        textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(position.x, position.y + 0.01, position.z)
        textNode.scale = SCNVector3(0.01, 0.01, 0.01)
        
        textNode.constraints = [SCNBillboardConstraint()] // чтобы 3D текст был повернут к камере всегда
        
        sceneView.scene.rootNode.addChildNode(textNode)
    }
}

