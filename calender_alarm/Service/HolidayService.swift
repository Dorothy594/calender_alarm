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

struct Holiday: Decodable, Identifiable, Hashable {
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
    private init() {}

    func fetchHolidays() async throws -> [Holiday] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(BankHolidayResponse.self, from: data).englandAndWales.events
    }
}
