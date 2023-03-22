// в инфоплисте - дать разрешение камере
import UIKit
import SceneKit
import ARKit

class GameAnimalViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    var score = Int()  // хранение результатов
    
    //MARK: - переменные
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var timerOutlet: UILabel! { didSet {// таймера на проигрывателе
        timerOutlet.layer.cornerRadius = timerOutlet.frame.size.height / 2
        timerOutlet.layer.borderColor = UIColor.black.cgColor
        timerOutlet.layer.borderWidth = 2
        timerOutlet.layer.backgroundColor = UIColor.systemOrange.cgColor
        score = 0
    }}
    @IBOutlet weak var scoreOutlet: UILabel! { didSet {// счет игрока
        scoreOutlet.layer.cornerRadius = scoreOutlet.frame.size.height / 2
        scoreOutlet.layer.borderColor = UIColor.black.cgColor
        scoreOutlet.layer.borderWidth = 2
        scoreOutlet.layer.backgroundColor = UIColor.systemOrange.cgColor
    }}
    
    @IBOutlet weak var targetOutlet: UIImageView! { didSet { // прицел
        let newTargetOutlet = targetOutlet.image?.withRenderingMode(.alwaysTemplate) // withRenderingMode - возвращает новую версию изображения, использующего указанный режим визуализации.  alwaysTemplate - игнорируя информацию о его цвете
        targetOutlet.image = newTargetOutlet
        targetOutlet.tintColor = .red
    }}
    
    //MARK: - кнопки
    
    @IBAction func closeButton(_ sender: UIButton) {
        seconds = 0
    }
    
    @IBOutlet weak var onFlyOutlet: UIButton! { didSet { // улиточка // банана
        onFlyOutlet.layer.cornerRadius = onFlyOutlet.frame.size.height / 2
        onFlyOutlet.layer.borderColor = UIColor.black.cgColor
        onFlyOutlet.layer.borderWidth = 2
    }}
    @IBOutlet weak var onBananaOutlet: UIButton! { didSet {
        onBananaOutlet.layer.cornerRadius = onBananaOutlet.frame.size.height / 2
        onBananaOutlet.layer.borderColor = UIColor.black.cgColor
        onBananaOutlet.layer.borderWidth = 2
    }}
    @IBOutlet weak var onFishOutlet: UIButton!  { didSet { // рыбка
        onFishOutlet.layer.cornerRadius = onFishOutlet.frame.size.height / 2
        onFishOutlet.layer.borderColor = UIColor.black.cgColor
        onFishOutlet.layer.borderWidth = 2
    }}
    
    @IBAction func onFlyButton(_ sender: UIButton) { fireMissile(type: "fly") }
    @IBAction func onBananaButton(_ sender: UIButton) { fireMissile(type: "banana") }
    @IBAction func onFishButton(_ sender: UIButton) { fireMissile(type: "fish") }
    

    //MARK: - функция с математикой, достает направление нашего просмотра (векторы направления в 3д пространстве)
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position) направление, положение
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // матрица преобразования 4x4, описывающая камеру в мировом пространстве
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // ориентация камеры в мировом пространстве
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // расположение камеры в мировом пространстве
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
    
    //MARK: - функции просмотра
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self // делегируем основные события из сцены (началась обработка, закончилась, произошла ошибка)
        sceneView.scene.physicsWorld.contactDelegate = self // делегат физики колизий (столкновений) реализует метод - physicsWorld
        playSound(sound: "gong", format: "wav") // гонг старта до формирования моделей - чтобы не наложился на фоновую музыку
        addTargetNodes() // добавим объекты животных
        runTimer() //таймер запуска
        //sceneView.showsStatistics = true  // статистика, (частота кадров в секунду и информация о времени)
    }
    
    override func viewWillAppear(_ animated: Bool) { // показ экрана
        super.viewWillAppear(animated)
    
        
        let configuration = ARWorldTrackingConfiguration() // создание конфигурации мира
        sceneView.session.run(configuration) // запуск сеанс просмотра - продолжаем текущую сессия и передаем текущую конфигурацию по умолчанию (при необходимости система запросит доступ к камере - необходимо указать в инфоплисте доступ к камере и сообщение)
    }
    
    override func viewWillDisappear(_ animated: Bool) { // исчезновение экрана
        super.viewWillDisappear(animated)
    
        sceneView.session.pause()  //Приостановка сеанс просмотра - все на паузу
    }
    
    // MARK: - таймер
    var seconds = 60 // сколько секунд длится игра
    var timer = Timer()
  //  var isTimerRunning = false // отслеживаем, включен ли таймер
    
    func runTimer() { // запуск таймера
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(self.updateTimer)), userInfo: nil, repeats: true)
    }
    
    // уменьшаем секунды на 1, обновляет метку таймера и вызывает GameOver, если секунды равны 0
    @objc func updateTimer() {
        if seconds == 0 {
            timer.invalidate()
            gameOver()
        } else {
            seconds -= 1
            timerOutlet.text = "\(seconds)"
        }
    }
    
    //сброс таймера
    func resetTimer() {
        timer.invalidate()
        seconds = 60
        timerOutlet.text = "\(seconds)"
    }
    
    // MARK: - game over
    func gameOver(){
        Score.shared.scoreAnimal = score
        self.dismiss(animated: true, completion: nil)  // возврат к контроллеру домашнего просмотра
        playSound(sound: "game-over", format: "wav")
    }
    
    // MARK: - ракеты и цели
    // создает узел снаряда (банан, муха или рыба), его запуск
    func fireMissile(type : String){
        
        var node = SCNNode()
        node = createMissile(type: type) // создаем узел: снаряд
        
        // узнаем положение и направление пользователей
        let (direction, position) = self.getUserVector()
        node.position = position // задаем эту позицию для снаряда
        var nodeDirection = SCNVector3()
        
        switch type {
        case "fly": // задаем направление (*4-ускорение)
            nodeDirection  = SCNVector3(direction.x*4,direction.y*4,direction.z*4)
            node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0,0,0.1), asImpulse: true) // applyForce - движение вперед, asImpulse - применили действие и он дальше летит)  SCNVector3 - объект крутится
            playSound(sound: "1-start-frog", format: "wav")
        case "banana":
            nodeDirection  = SCNVector3(direction.x*4,direction.y*4,direction.z*4)
            node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
            playSound(sound: "3-start-monkey", format: "mp3")
        case "fish":
            nodeDirection  = SCNVector3(direction.x*4,direction.y*4,direction.z*4)
            node.physicsBody?.applyForce(nodeDirection, at: SCNVector3(0.1,0,0), asImpulse: true)
            playSound(sound: "2-start-penguin", format: "wav")
        default:
            nodeDirection = direction
        }
        
        node.physicsBody?.applyForce(nodeDirection, asImpulse: true) // переместить узел
        sceneView.scene.rootNode.addChildNode(node) // добавляем узел в сцену - и банан летит в дополненнной реальности
    }
    
    // создаем узлы - 3д объекты, которые будут вылетать из позиции пользователя и летят в сторону объекта
    func createMissile(type : String) -> SCNNode{ // создает по типу, которые мы ей указывали
        var node = SCNNode()
        
        switch type {  // оператор case для разрешения изменений масштаба и поворотов
        case "fly":
            let scene = SCNScene(named: "Snail.usdz")
            node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)!
            node.scale = SCNVector3(0.005,0.005,0.005) // размеры
            node.name = "fly"
        case "banana":
            let scene = SCNScene(named: "Banana.usdz")
            node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)!
            node.scale = SCNVector3(0.02,0.02,0.02)
            node.name = "banana"
        case "fish":
            let scene = SCNScene(named: "salmon_Fish.usdz")
            node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)!
            node.scale = SCNVector3(0.005,0.005,0.005)
            node.name = "fish"
        default:
            node = SCNNode()
        }
        
        //физическое тело определяет, как объект взаимодействует с другими объектами и окружающей средой
        node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) // создаем физическое тело
        node.physicsBody?.isAffectedByGravity = false // тело не подвержено гравитации
        
        //эти битовые маски использовались для определения "столкновений" с другими объектами
        node.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
        node.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
        
        return node
    }
    
    // генерация дополненной реальности: добавление объектов на сцену, вращение и размещение в случайных местах вокруг игрока
    func addTargetNodes(){
        for index in 1...45 { // количество объектов
            
            var node = SCNNode() // объект
            
            let indexString = String(index)
            print(" index = \(index), suffix = \(indexString.suffix(1))")
            
            // настройка нода (объекат) по последней цифре индекса
            if (indexString.suffix(1) == "1") || (indexString.suffix(1) == "2") || (indexString.suffix(1) == "3") || (indexString.suffix(1) == "4"){ // лягушка
                let scene = SCNScene(named: "Australian_Tree_Frog.usdz") // достаем сцену с лягушкой (сценграф)
                node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)! // достаем нод
                node.scale = SCNVector3(0.002,0.002,0.002) // в 3д-мире создаем скейл - трансформируем и уменьшаем
                node.name = "frog" // задаем имя
            } else if (indexString.suffix(1) == "5") || (indexString.suffix(1) == "6") || (indexString.suffix(1) == "7") { // обезьяна
                let scene = SCNScene(named: "King_Monkey.usdz")
                node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)!
                node.scale = SCNVector3(0.03,0.03,0.03)
                node.name = "monkey"
            } else if (indexString.suffix(1) == "8") || (indexString.suffix(1) == "9") || (indexString.suffix(1) == "0") { // пингвин
                let scene = SCNScene(named: "Pinguin.usdz")
                node = (scene?.rootNode.childNode(withName: "scene", recursively: true)!)!
                node.scale = SCNVector3(0.03,0.03,0.03)
                node.name = "penguin"
            } else { break }
    
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil) // создаем физические тела созданным нодам
            node.physicsBody?.isAffectedByGravity = false // не влияет гравитация
            
            // размещаем случайным образом, в пределах пороговых значений
            node.position = SCNVector3(randomFloat(min: -10, max: 10),randomFloat(min: -4, max: 5),randomFloat(min: -10, max: 10)) // задаем позицию - случайным образом
            
            //rotate действие анимации - вращение нодов вокруг себя: создаем сцену ротейт (вращение) - 3д вектором и скорость
            let action: SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 1.0)
            let forever = SCNAction.repeatForever(action) // бесконечное повторение
            node.runAction(forever) // наш нод выполняет это действие
            
            //для обнаружения столкновений
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue // таргет
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            
            //добавить в сцену
            sceneView.scene.rootNode.addChildNode(node) // в конце цикла в родительский нод в чайлднот добавляем созданный нод
        }
    }
    
    // создание случайной позиции между указанными диапазонами
    func randomFloat(min: Float, max: Float) -> Float {
        return (Float(arc4random()) / 4294967296) * (max - min) + min
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Освободите все кэшированные данные, изображения и т.д., Которые не используются.
    }

    // MARK: - ARSCNViewDelegate
/*
    // переопределение для создания и настройки узлов для привязок, добавленных в сеанс представления.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Предоставить пользователю сообщение об ошибке
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Информировать пользователя о том, что сеанс был прерван, например, путем представления наложения
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Сбросьте отслеживание и / или удалите существующие привязки, если требуется последовательное отслеживание
    }
*/
    
    // MARK: - Contact Delegate
   
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) { // столкновение 2 сущностей
        
         print("*** Collision! " + contact.nodeA.name! + " hit " + contact.nodeB.name! + "***") // столкнувшиеся сущности
        
        //  проверим, что хотя бы одна сущность является нашей целью
        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue {
            
            let  explosion = SCNParticleSystem(named: "Crash", inDirectory: nil) // эффект взрыва прис толкновении
          //  contact.nodeB.addParticleSystem(explosion!) // добавим взрыв
            
            if ((contact.nodeA.name! == "frog" && contact.nodeB.name! == "fly")) ||
                ((contact.nodeA.name! == "fly" && contact.nodeB.name! == "frog")) {
                score += 1
             //   playSound(sound: "explosion", format: "wav")
                playSound(sound: "1-finish2-fly", format: "wav")
                contact.nodeB.addParticleSystem(explosion!) // добавим взрыв
                deleteNodeAnodeB()
            } else if ((contact.nodeA.name! == "monkey" && contact.nodeB.name! == "banana")) ||
                        ((contact.nodeA.name! == "banana" && contact.nodeB.name! == "monkey")){
                score += 1
                playSound(sound: "3-finish2_2-monkey", format: "wav")
                contact.nodeB.addParticleSystem(explosion!) // добавим взрыв
                    deleteNodeAnodeB()
            } else if ((contact.nodeA.name! == "penguin" && contact.nodeB.name! == "fish")) ||
                        ((contact.nodeA.name! == "fish" && contact.nodeB.name! == "penguin")){
                score += 1
                playSound(sound: "2-finish2-penguin", format: "wav")
                contact.nodeB.addParticleSystem(explosion!) // добавим взрыв
                deleteNodeAnodeB()
            } else if ((contact.nodeA.name! == "frog" && contact.nodeB.name! != "fly")) ||
                        ((contact.nodeA.name! == "monkey" && contact.nodeB.name! != "banana")) ||
                        ((contact.nodeA.name! == "penguin" && contact.nodeB.name! != "fish")){
                playSound(sound: "2-finish-Arrow", format: "wav")
                deleteNodeB()
            } else if ((contact.nodeA.name! == "fly" && contact.nodeB.name! != "frog")) ||
                        ((contact.nodeA.name! == "banana" && contact.nodeB.name! != "monkey")) ||
                        ((contact.nodeA.name! == "fish" && contact.nodeB.name! != "penguin")){
                playSound(sound: "2-finish-Arrow", format: "wav")
                deleteNodeA()
            }
          
            func deleteNodeAnodeB() { // удаляем оба объекта
                DispatchQueue.main.async { // удаляем на главном потоке (столкновения происходят по умолчанию на фоновом потоке)
                    contact.nodeA.removeFromParentNode()
                    contact.nodeB.removeFromParentNode()
                    self.scoreOutlet.text = String(self.score) // обрабатывается на главном потоке
                }
            }
            
            func deleteNodeB() { // удаляем только снаряд
                DispatchQueue.main.async {
                    contact.nodeB.removeFromParentNode()
                    self.scoreOutlet.text = String(self.score)
                }
            }
            
            func deleteNodeA() { // удаляем только снаряд
                DispatchQueue.main.async {
                    contact.nodeA.removeFromParentNode()
                   
                }
            }
        }
    }
    
    // MARK: - sounds
    
    var player: AVAudioPlayer?
    
    func playSound(sound : String, format: String) {
        guard let url = Bundle.main.url(forResource: sound, withExtension: format) else { return }
        do {
          //  try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            
            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    // MARK: - включение - выключение фоновой музыки
    @IBOutlet weak var switchMusicOutlet: UIButton! { didSet {
        let imgName = UIImage(named: "musicOn100.png")!
        switchMusicOutlet.setImage(imgName, for: .normal)
        playBackgroundMusic()
    }}
    
    var flag = true // музыка играет
    
    @IBAction func switchMusicButton(_ sender: UIButton) {
        flag = !flag
        setButtonImage()
        playBackgroundMusic()
    }
    
    func setButtonImage() { // смена иконки кнопки
        let img = flag ? "musicOn100" : "musicOff100"
        let imgName = UIImage(named: "\(img).png")!
        switchMusicOutlet.setImage(imgName, for: .normal)
    }
    
   let audioNode = SCNNode() // в этой области видимости (если убрать в playBackgroundMusic - то нес работает переключение на режим без музыки)
    
    func playBackgroundMusic() {
    
        let audioSource = SCNAudioSource(fileNamed: "let-me-see.mp3")! //(fileNamed: "music-box.mp3")!
        audioSource.loops = true // повтор музыки после завершения
        let audioPlayer = SCNAudioPlayer(source: audioSource)
        let play = SCNAction.playAudio(audioSource, waitForCompletion: true)
        let stop = SCNAction.removeFromParentNode()
        
        guard flag != false else {
            audioNode.runAction(stop)
            return
        }
        audioNode.addAudioPlayer(audioPlayer)
        audioNode.runAction(play)
        sceneView.scene.rootNode.addChildNode(audioNode)
    }
}
