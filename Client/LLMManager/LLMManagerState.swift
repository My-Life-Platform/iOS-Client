import Foundation
import MLXLMCommon

enum LLMManagerState {
    case idle
    case loaded(ModelContainer)
}
