import HotwireNative
import UIKit

/// A bridge component that displays a `UISearchController` in the navigation bar.
/// This component responds to the "search" name from the web side.
final class SearchComponent: BridgeComponent {
    /// The name of the bridge component used to register with the web view.
    override class var name: String { "search" }

    // MARK: - Properties

    /// The system search controller.
    private let searchController = UISearchController(searchResultsController: nil)
    
    /// Helper object to handle search result updates and search bar delegate calls.
    private lazy var searchResultsUpdater = SearchResultsUpdater(component: self)

    /// The view controller that's currently displaying the bridge component's destination.
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    // MARK: - BridgeComponent

    /// Called when a message is received from the web side.
    /// - Parameter message: The message object containing the event and data.
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else { return }

        switch event {
        case .connect:
            addSearchController()
        }
    }

    // MARK: - Private Methods

    /// Configures and adds the `UISearchController` to the navigation bar.
    private func addSearchController() {
        searchController.searchResultsUpdater = searchResultsUpdater
        // Required for capturing the "Search" button tap on the keyboard
        searchController.searchBar.delegate = searchResultsUpdater 

        viewController?.navigationItem.searchController = searchController
        viewController?.navigationItem.hidesSearchBarWhenScrolling = false
        viewController?.definesPresentationContext = true
    }

    /// Sends the search query back to the web side.
    /// - Parameter query: The text entered by the user in the search bar.
    fileprivate func updateSearchResults(with query: String?) {
        let data = QueryMessageData(query: query)
        reply(to: Event.connect.rawValue, with: data)
    }
}

// MARK: - Events & Data Models

private extension SearchComponent {
    /// Events that this component can handle.
    enum Event: String {
        /// Connects the search component and shows the search bar.
        case connect
    }

    /// The data structure sent back to the web side containing the search query.
    struct QueryMessageData: Encodable {
        let query: String?
    }
}

// MARK: - Helper Classes

/// Internal class to manage `UISearchResultsUpdating` and `UISearchBarDelegate` callbacks.
private class SearchResultsUpdater: NSObject, UISearchResultsUpdating, UISearchBarDelegate {
    private unowned let component: SearchComponent

    init(component: SearchComponent) {
        self.component = component
    }

    /// Called when the search bar text changes.
    func updateSearchResults(for searchController: UISearchController) {
        // Implementation can be added for real-time search if needed.
    }

    /// Called when the user taps the "Search" button on the keyboard.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        component.updateSearchResults(with: searchBar.text)
        searchBar.resignFirstResponder()
    }
}
