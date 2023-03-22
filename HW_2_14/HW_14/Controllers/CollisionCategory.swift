
import Foundation


// MARK: - обработка колизий (игра Animal, игра Ball)
struct CollisionCategory: OptionSet { // обработка колизий (столкновений)
    let rawValue: Int
    
    static let missileCategory  = CollisionCategory(rawValue: 1 << 0) // то что вылетает по нажатию (снаряд)
    static let targetCategory = CollisionCategory(rawValue: 1 << 1) // то что изначально генерируем, то во что врезаются снаряды (цель)
    static let otherCategory = CollisionCategory(rawValue: 1 << 2)
}
