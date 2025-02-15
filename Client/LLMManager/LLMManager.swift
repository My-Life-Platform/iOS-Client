import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import MLXRandom
import Combine

final class LLMManager {

    private static let modelInstalledKey = "my.life.modelInstalled"

    // forgive me for now
    static let shared = LLMManager()

    private(set) var isModelInstalled: Bool {
        get {
            self.isModelInstalledSubject.value
        }

        set {
            self.isModelInstalledSubject.value = newValue

            UserDefaults.standard.set(newValue, forKey: Self.modelInstalledKey)
        }
    }

    private(set) var state: LLMManagerState {
        get {
            self.stateSubject.value
        }

        set {
            self.stateSubject.value = newValue
        }
    }

    private(set) var downloadProgress: Float {
        get {
            self.downloadProgressSubject.value
        }

        set {
            self.downloadProgressSubject.value = newValue
        }
    }

    let isModelInstalledPublisher: AnyPublisher<Bool, Never>

    let statePublisher: AnyPublisher<LLMManagerState, Never>

    let downloadProgressPublisher: AnyPublisher<Float, Never>

    private let isModelInstalledSubject: CurrentValueSubject<Bool, Never>

    private let stateSubject: CurrentValueSubject<LLMManagerState, Never>

    private let downloadProgressSubject: CurrentValueSubject<Float, Never>

    private let syncQueue = DispatchQueue(label: "LLMManager")

    private let generateParameters = GenerateParameters(temperature: 0.5)

    private let maxTokens = 4096

    init() {
        let isModelInstalled = UserDefaults.standard.bool(forKey: Self.modelInstalledKey)

        let isModelInstalledSubject = CurrentValueSubject<Bool, Never>(isModelInstalled)
        self.isModelInstalledSubject = isModelInstalledSubject
        self.isModelInstalledPublisher = isModelInstalledSubject.eraseToAnyPublisher()

        let stateSubject = CurrentValueSubject<LLMManagerState, Never>(.idle)
        self.stateSubject = stateSubject
        self.statePublisher = stateSubject.eraseToAnyPublisher()

        let downloadProgressSubject = CurrentValueSubject<Float, Never>(isModelInstalled ? 100 : 0)
        self.downloadProgressSubject = downloadProgressSubject
        self.downloadProgressPublisher = downloadProgressSubject.eraseToAnyPublisher()
    }

    @discardableResult
    func loadModel() async throws -> ModelContainer {
        let model = ModelConfiguration.llama_3_2_3b_4bit

        switch self.state {
        case .idle:
            MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)

            let modelContainer = try await LLMModelFactory.shared.loadContainer(configuration: model) { [weak self] progress in
                guard let self else {
                    return
                }

                self.syncQueue.async {
                    self.downloadProgress = Float(progress.fractionCompleted)
                }
            }

            self.syncQueue.async {
                self.isModelInstalled = true
                self.state = .loaded(modelContainer)
            }

            return modelContainer
        case .loaded(let modelContainer):
            return modelContainer
        }
    }

    func generate(modelName: String, history: [[String: String]]) async -> String {
        do {
            let modelContainer = try await self.loadModel()

            let params = self.generateParameters

            let maxTokens = self.maxTokens

            MLXRandom.seed(UInt64(Date.timeIntervalSinceReferenceDate * 1000))

            let result = try await modelContainer.perform { context in
                let input = try await context.processor.prepare(input: .init(messages: history))

                return try MLXLMCommon.generate(input: input,
                                                parameters: params,
                                                context: context) { tokens in
                    if tokens.count >= maxTokens {
                        return .stop
                    } else {
                        return .more
                    }
                }
            }

            return result.output
        } catch {
            return "Failed"
        }
    }
}
