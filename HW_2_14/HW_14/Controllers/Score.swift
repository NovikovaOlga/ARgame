
import Foundation

class Score { // хранение результатов игры
    
    static let shared = Score()
    
    private let scoreAnimalKey = "Score.scoreAnimalKey" // животные
    private let scoreBallKey = "Score.scoreBallKey" // мячи
    private let scoreRulerKey = "Score.scoreRulerKey" // замеры
    
    var scoreAnimal: Int {
        set { UserDefaults.standard.set(newValue, forKey: scoreAnimalKey) }
        get { return UserDefaults.standard.integer(forKey: scoreAnimalKey) }
    }
    
    var scoreBall: Int {
        set { UserDefaults.standard.set(newValue, forKey: scoreBallKey) }
        get { return UserDefaults.standard.integer(forKey: scoreBallKey)  }
    }
    
    var scoreRuler: String {
        set { UserDefaults.standard.set(newValue, forKey: scoreRulerKey) }
        get { return UserDefaults.standard.string(forKey: scoreRulerKey) ?? "" }
    }
}
