import Foundation
import Combine
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recentScans: [ScanResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
        loadRecentScans()
    }

    func loadRecentScans() {
        isLoading = true

        dataService.getRecentScans(limit: 5)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.showError(error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] scans in
                    self?.recentScans = scans
                }
            )
            .store(in: &cancellables)
    }

    func handleScanResult(_ scanResult: ScanResult) {
        recentScans.insert(scanResult, at: 0)
        if recentScans.count > 5 {
            recentScans.removeLast()
        }

    }

    func clearRecentScans() {
        recentScans.removeAll()
        dataService.clearScanHistory()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        AppLog.warning("Failed to clear scan history: \(error.localizedDescription)", category: .persistence)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

protocol DataServiceProtocol {
    func getRecentScans(limit: Int) -> AnyPublisher<[ScanResult], Error>
    func clearScanHistory() -> AnyPublisher<Void, Error>
}

final class DataService: DataServiceProtocol {
    static let shared = DataService()
    private let coreDataManager: CoreDataManager

    private init(coreDataManager: CoreDataManager = .shared) {
        self.coreDataManager = coreDataManager
    }

    func getRecentScans(limit: Int) -> AnyPublisher<[ScanResult], Error> {
        Future { [coreDataManager] promise in
            Task(priority: .utility) {
                do {
                    let histories = try coreDataManager.fetchScanHistory(limit: limit)
                    let scans = histories.compactMap { history -> ScanResult? in
                        guard let barcode = history.value(forKey: "productBarcode") as? String, !barcode.isEmpty else {
                            return nil
                        }
                        let timestamp = (history.value(forKey: "scanDate") as? Date) ?? Date()
                        return ScanResult(barcode: barcode, type: .ean13, timestamp: timestamp)
                    }
                    promise(.success(scans))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func clearScanHistory() -> AnyPublisher<Void, Error> {
        Future { [coreDataManager] promise in
            Task(priority: .utility) {
                do {
                    try coreDataManager.clearScanHistory()
                    promise(.success(()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
