
import UIKit

class GameBallStartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        scoreBallLabel.text = "Last Score: \(String(Score.shared.scoreBall))"
    }
    
    @IBAction func onPlayBallButton(_ sender: Any) {
        performSegue(withIdentifier: "toGameBall", sender: self)
    }
    
    @IBOutlet weak var scoreBallLabel: UILabel!
    
}
