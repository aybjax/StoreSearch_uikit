//
//  ViewController.swift
//  StoreSearch
//
//  Created by aybjax on 6/6/21.
//

import UIKit

class SearchViewController: UIViewController {
    
    struct TableView {
        struct CellIdentifier {
            static let searchResultCell = "SearchResultCell"
            static let nothingFoundCell = "NothingFoundCell"
            static let LoadingCell = "LoadingCell"
        }
    }
    
    // Properties
    // ==========
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.becomeFirstResponder()
        // Do any additional setup after loading the view.
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0,
                                              bottom: 0, right: 0)
        
        // instead of dragging
        tableView.delegate = self
        tableView.dataSource = self
        // ==========================
        
        var cellNib = UINib(nibName: TableView.CellIdentifier.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifier.searchResultCell)
        cellNib = UINib(nibName: TableView.CellIdentifier.nothingFoundCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifier.nothingFoundCell)
        cellNib = UINib(nibName: TableView.CellIdentifier.LoadingCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableView.CellIdentifier.LoadingCell)
    }


}



extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = []
            
            /*
             Async queue medium
             */
            let queue = DispatchQueue.global()
            let url = iTunesURL(searchText: searchBar.text!)
            
            queue.async {
                if let data = self.performStoreRequest(with: url) {
                    self.searchResults = self.parse(data: data)
    //                searchResults.sort(by: {result1, result2 in
    //                    return result1.name.localizedStandardCompare(result2.name)
    //                        == .orderedAscending
    //                })
                    
    //                searchResults.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending}
                    
    //                searchResults.sort { $0 < $1}
                    
                    self.searchResults.sort(by: <)
                }
                
                print("DONE")
                
                /*
                 UI in main queue
                 */
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.tableView.reloadData()
                }
            }
        }
        
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}



extension SearchViewController: UITableViewDelegate,
                                UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        }
        else if !hasSearched {
            return 0
        }
        else if searchResults.count == 0 {
            return 1
        }
        else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifier.LoadingCell, for: indexPath)
            
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView

            spinner.startAnimating()
            
            return cell
        }
        
        if searchResults.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: TableView.CellIdentifier.nothingFoundCell, for: indexPath)
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
            let searchResult = searchResults[indexPath.row]
            cell.nameLabel.text = searchResult.name
            
            if searchResult.artist.isEmpty {
                cell.artistNameLabel.text = "Unknown"
            }
            else {
                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artist, searchResult.type)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        }
        else {
            return indexPath
        }
    }
}


extension SearchViewController {
    // MARK: - synchronous
    func iTunesURL(searchText: String) -> URL {
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
        
        let urlString = String(format: "https://itunes.apple.com/search?term=%@&limit=1000", encodedText)
        
        let url = URL(string: urlString)
        
        return url!
    }
    
    func performStoreRequest(with url: URL) -> Data? {
        do {
//            return String(contentsOf: url, encoding: .utf8)
            return try Data(contentsOf: url)
        }
        catch {
            print("Download Error \(error.localizedDescription)")
            showNetworkError()
            
            return nil
        }
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            
            return result.results
        }
        catch {
            print("JSON Error: \(error)")
            
            return []
        }
    }
    
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...",
                                      message: "There was an error accessing the iTunes Store."
                                        + " Please try again", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}
