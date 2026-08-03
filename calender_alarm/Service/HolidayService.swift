import Foundation

struct BankHolidayResponse: Decodable {
    let englandAndWales: Region

    enum CodingKeys: String, CodingKey {
        case englandAndWales = "england-and-wales"
    }
}

struct Region: Decodable {
    let events: [Holiday]
}

struct Holiday: Codable, Identifiable, Hashable {
    let title: String
    let date: String
    var id: String { date }

    var dateValue: Date? {
        Self.dateFormatter.date(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .uk
        formatter.timeZone = TimeZone(identifier: "Europe/London")
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

final class HolidayService {
    static let shared = HolidayService()
    private let url = URL(string: "https://www.gov.uk/bank-holidays.json")!
    private let cacheKey = "cachedEnglandAndWalesHolidays"
    private init() {}

    func fetchHolidays() async throws -> [Holiday] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let holidays = try JSONDecoder().decode(BankHolidayResponse.self, from: data).englandAndWales.events
        saveToCache(holidays)
        return holidays
    }

    func cachedHolidays() -> [Holiday] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return [] }
        return (try? JSONDecoder().decode([Holiday].self, from: data)) ?? []
    }

    private func saveToCache(_ holidays: [Holiday]) {
        guard let data = try? JSONEncoder().encode(holidays) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }
}
