
import UIKit

class GameAnimalStartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
            scoreAnimalLabel.text = "Last Score: \(String(Score.shared.scoreAnimal))"
     
    }
        @IBAction func onPlayAnimalButton(_ sender: Any) {
        performSegue(withIdentifier: "toGameAnimal", sender: self)
    }
    
    @IBOutlet weak var scoreAnimalLabel: UILabel!

}


