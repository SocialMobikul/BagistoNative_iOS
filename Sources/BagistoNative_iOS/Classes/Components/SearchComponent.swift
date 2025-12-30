
import HotwireNative
import UIKit

final class SearchComponent: BridgeComponent {
    override class var name: String { "search" }

    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var searchResultsUpdater = SearchResultsUpdater(component: self)

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .connect:
            addSearchController()
        }
    }

    private func addSearchController() {
        searchController.searchResultsUpdater = searchResultsUpdater
        searchController.searchBar.delegate = searchResultsUpdater // ✅ required for Search button tap

        viewController?.navigationItem.searchController = searchController
        viewController?.navigationItem.hidesSearchBarWhenScrolling = false
        viewController?.definesPresentationContext = true
    }

    fileprivate func updateSearchResults(with query: String?) {
        print("Query Submitted: \(query ?? "")") // ✅ For testing
        let data = QueryMessageData(query: query)
        reply(to: Event.connect.rawValue, with: data)
    }
}

private extension SearchComponent {
    enum Event: String {
        case connect
    }

    struct QueryMessageData: Encodable {
        let query: String?
    }
}

private class SearchResultsUpdater: NSObject, UISearchResultsUpdating, UISearchBarDelegate {
    private unowned let component: SearchComponent

    init(component: SearchComponent) {
        self.component = component
    }

    // Optional: for real-time update while typing (keep it empty if not needed)
    func updateSearchResults(for searchController: UISearchController) {}

    // Called when user taps "Search" button on keyboard
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        component.updateSearchResults(with: searchBar.text)
        searchBar.resignFirstResponder()
    }
}
