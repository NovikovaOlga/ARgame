
import UIKit
import SceneKit
import ARKit

class GameBallViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    var colors = [
        UIColor.systemPink,
        UIColor.systemBlue,
        UIColor.systemYellow,
        UIColor.systemGreen,
        UIColor.systemPurple,
        UIColor.systemOrange]
    
    var score = Int()  // хранение результатов
    var boxes = 0 // коробки
    var sphereColor: UIColor = .systemPink // дефолтный цвет
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    @IBOutlet weak var collectionColorBall: UICollectionView!
    
    @IBOutlet weak var timerOutlet: UILabel! { didSet { // таймер на проигрывателе
        timerOutlet.layer.cornerRadius = timerOutlet.frame.size.height / 2
        timerOutlet.layer.borderColor = UIColor.black.cgColor
        timerOutlet.layer.borderWidth = 2
        timerOutlet.layer.backgroundColor = UIColor.systemOrange.cgColor
    }}
    
    @IBOutlet weak var scoreOutlet: UILabel! { didSet { // счет игрока
        scoreOutlet.layer.cornerRadius = scoreOutlet.frame.size.height / 2
        scoreOutlet.layer.borderColor = UIColor.black.cgColor
        scoreOutlet.layer.borderWidth = 2
        scoreOutlet.layer.backgroundColor = UIColor.systemOrange.cgColor
        score = 0
    }}
    
    @IBAction func closeButton(_ sender: Any) {
        seconds = 0
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self // делегат ARSCNViewDelegate
      
        sceneView.scene.physicsWorld.contactDelegate = self // делегат SCNPhysicsContactDelegate (физика колизий (столкновений) реализует метод - physicsWorld)
        playSound(sound: "metalgong", format: "wav") // гонг старта до формирования моделей - чтобы не наложился на фоновую музыку
        self.collectionColorBall.delegate = self
        self.drawTarget()
        addTargetNodes() // добавим кубы
        runTimer() //таймер запуска
        // sceneView.showsStatistics = true // Показывать статистику, такую как частота кадров в секунду и информация о времени
    }
    
    // MARK: - таймер
    var seconds = 45 // сколько секунд длится игра
    var timer = Timer()
   // var isTimerRunning = false // отслеживаем, включен ли таймер
    
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
        seconds = 45
        timerOutlet.text = "\(seconds)"
    }
    
    // MARK: - game over
    func gameOver(){
        Score.shared.scoreBall = score
        self.dismiss(animated: true, completion: nil)  // возврат к контроллеру домашнего просмотра
        playSound(sound: "game-over", format: "wav")
    }
    
    let shapeLayer = CAShapeLayer()
    
    func drawTarget() { // прицел (внутри будет закрашиваться выбранным цветом)
        let path = UIBezierPath(ovalIn: CGRect(x: self.view.center.x - 10, y: self.view.center.y - 30, width: 40, height: 40)) //   let path = UIBezierPath(ovalIn: CGRect(x: self.view.center.x - 10, y: self.view.center.y - 10, width: 40, height: 40))
    //    let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = .none
        shapeLayer.lineWidth = 4
        shapeLayer.strokeColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.view.layer.addSublayer(shapeLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration() // конфигурация сеанса
        sceneView.session.run(configuration)  // запуск сеанс просмотра
        // configuration.planeDetection = .horizontal // обнаружение горизонтальной плоскости
    }
    
    // генерация дополненной реальности: добавление объектов на сцену, вращение и размещение в случайных местах вокруг игрока
    func addTargetNodes(){
        for _ in 1...100 { // количество объектов
            
            let node = SCNNode() // объект
            
            node.name = "box" // размеры куба
            let nodeForm = SCNBox(
                width:  CGFloat.random(in: 1...3),
                height: CGFloat.random(in: 1...3),
                length: CGFloat.random(in: 1...3),
                chamferRadius: 0)
            
            node.geometry = nodeForm
            let shape = SCNPhysicsShape(geometry: nodeForm, options: nil)
            node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape) // создаем физические тела созданным нодам
            node.physicsBody?.isAffectedByGravity = false // не влияет гравитация
            
            // битовая маска для обнаружения столкновения
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            
            node.geometry?.firstMaterial?.diffuse.contents = self.colors.randomElement()!
            node.geometry?.firstMaterial?.isDoubleSided = true
            
            node.position = SCNVector3(  // размещаем случайным образом, в пределах пороговых значений
                x: Float.random(in: -10...10),
                y: Float.random(in: -10...10),
                z: Float.random(in: -10...10))
          
            //rotate действие анимации - вращение нодов вокруг себя: создаем сцену ротейт (вращение) - 3д вектором и скорость
            let action: SCNAction = SCNAction.rotate(by: .pi, around: SCNVector3(0, 1, 0), duration: 2)
            let forever = SCNAction.repeatForever(action) // бесконечное повторение
            node.runAction(forever) // наш нод выполняет это действие
            
            //для обнаружения столкновений
            node.physicsBody?.categoryBitMask = CollisionCategory.targetCategory.rawValue // таргет
            node.physicsBody?.contactTestBitMask = CollisionCategory.missileCategory.rawValue
            
            //добавить в сцену
            sceneView.scene.rootNode.addChildNode(node) // в конце цикла в родительский нод в чайлднот добавляем созданный нод
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Приостановите сеанс просмотра
        sceneView.session.pause() //Приостановка сеанс просмотра - все на паузу
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { // выстрел
        super.touchesBegan(touches, with: event)
        if touches.first != nil {
         //   print("touches.first != nil")
            let (dir, pos) = self.getUserVector() // узнаем положение и направление пользователей
            var nodeDir = SCNVector3()
            
            let nodeForm = SCNSphere(radius: 0.15)
            nodeForm.firstMaterial?.diffuse.contents = sphereColor
            nodeForm.firstMaterial?.isDoubleSided = true
            
            let sphere = SCNNode(geometry: nodeForm)
            sphere.name = "sphere"
            sphere.position = pos
            
            sphere.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            sphere.physicsBody?.isAffectedByGravity = false
            
            // битовая маска для обнаружения столкновения
            sphere.physicsBody?.categoryBitMask = CollisionCategory.missileCategory.rawValue
            sphere.physicsBody?.collisionBitMask = CollisionCategory.targetCategory.rawValue
            
            nodeDir = SCNVector3(dir.x*4,dir.y*4,dir.z*4)
            sphere.physicsBody?.applyForce(nodeDir, asImpulse: true) // переместить узел
            
            sceneView.scene.rootNode.addChildNode(sphere) // добавляем узел в сцену - и шар летит в дополненнной реальности
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                sphere.removeFromParentNode() // принудительное удаление через 10 секунд
            }
        }
    }
    
    //MARK: - функция с математикой, достает направление нашего просмотра (векторы направления в 3д пространстве)
    func getUserVector() -> (SCNVector3, SCNVector3) { // (direction, position) направление, положение
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform) // матрица преобразования 4x4, описывающая камеру в мировом пространстве
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // ориентация камеры в пространстве
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // расположение камеры в пространстве
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2)) //return (SCNVector3(0, 0, 0), SCNVector3(0, 0, -0.1))
    }
    
    // MARK: - Contact Delegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) { // столкновение 2 сущностей

        if contact.nodeA.physicsBody?.categoryBitMask == CollisionCategory.targetCategory.rawValue || contact.nodeB.physicsBody?.categoryBitMask == CollisionCategory.missileCategory.rawValue {
            
            let  explosion = SCNParticleSystem(named: "CrashStar", inDirectory: nil) // эффект взрыва прис толкновении
            
            let sphereColor = contact.nodeA.geometry?.firstMaterial?.diffuse.contents as! UIColor
            let boxColor = contact.nodeB.geometry?.firstMaterial?.diffuse.contents as! UIColor
            

            if sphereColor == boxColor { // пропадают куб и шар
                score += 1
                playSound(sound: "bell-yes", format: "wav")
                contact.nodeB.addParticleSystem(explosion!) // добавим взрыв
                deleteNodeAnodeB()
            } else {
                playSound(sound: "bell-no", format: "aiff")
                deleteNodeB() // пропадает шар
            }
            
            func deleteNodeAnodeB() { // удаляем оба объекта
                DispatchQueue.main.async { // удаляем на главном потоке (столкновения происходят по умолчанию на фоновом потоке)
                    contact.nodeA.removeFromParentNode()
                    contact.nodeB.removeFromParentNode()
                    self.scoreOutlet.text = String(self.score) // отображаем новый счет игрока
                }
            }
            
            func deleteNodeB() { //  // пропадает шар
                DispatchQueue.main.async {
                    contact.nodeB.removeFromParentNode()
                }
            }
            
        }
    }
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        //Выдать пользователю сообщение об ошибке
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Информировать пользователя о том, что сеанс был прерван, например, путем представления наложения
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        //Сбросьте отслеживание и / или удалите существующие привязки, если требуется последовательное отслеживание
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
    
    @IBOutlet weak var switchMusicOutlet: UIButton!  { didSet {
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
    
    func playBackgroundMusic() { // проигрывание музыка
    
        let audioSource = SCNAudioSource(fileNamed: "music-box2.wav")! //(fileNamed: "music-box.mp3")!
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

extension GameBallViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GameBallCollectionViewCell
        cell.backgroundColor = colors[indexPath.row]
        cell.layer.cornerRadius = cell.frame.width / 2
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 2
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.sphereColor = colors[indexPath.row]
        shapeLayer.fillColor = sphereColor.cgColor
    }
}
