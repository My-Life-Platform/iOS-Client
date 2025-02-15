import Foundation
import MLXLMCommon

extension ModelConfiguration {

    static let llama_3_2_3b_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit"
    )

    var modelSize: Decimal? {
       switch self {
       case .llama_3_2_3b_4bit:
           return 1.8
       default:
           return nil
       }
   }

}

extension ModelConfiguration: @retroactive Equatable {

    public static func == (lhs: MLXLMCommon.ModelConfiguration, rhs: MLXLMCommon.ModelConfiguration) -> Bool {
        return lhs.name == rhs.name
    }
    
}

