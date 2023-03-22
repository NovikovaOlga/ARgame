
import UIKit

class GameRulerStartViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scoreRulerLabel.text = "Last Score: \(Score.shared.scoreRuler)"
    }
    
    @IBAction func onPlayRulerButton(_ sender: Any) {
        performSegue(withIdentifier: "toGameRuler", sender: self)
    }
    
    @IBOutlet weak var scoreRulerLabel: UILabel!
    
}
