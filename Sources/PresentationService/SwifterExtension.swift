import Swifter

extension HttpRequest {
    func queryParam(_ name: String) -> String? {
        queryParams
            .first(where: {(n, _) in n == name})
            .flatMap { (_, v) in v
                .replacingOccurrences(of: "+", with: " ")
                .removingPercentEncoding
            }
    }
}
