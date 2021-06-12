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
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    
    var dataTask: URLSessionDataTask?
    
    
    var landscapeVC: LandscapeViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.becomeFirstResponder()
        // Do any additional setup after loading the view.
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0,
                                              bottom: 0, right: 0)
        
        let segmentColor = UIColor(red: 10/255.0, green: 80/255.0, blue: 80/255.0, alpha: 1)
        let selectedTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        let normalTextAttributes = [NSAttributedString.Key.foregroundColor: segmentColor]
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
//        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .highlighted)
        
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
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        switch newCollection.verticalSizeClass {
        case .compact:
            showLandscape(with: coordinator)
        case .regular, .unspecified:
            hideLandscape(with: coordinator)
        @unknown default:
            fatalError()
        }
    }

    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destination as! DetailViewController
            let indexPath = sender as! IndexPath
            
            let searchResult = searchResults[indexPath.row]
            
            detailViewController.searchResult = searchResult
        }
    }
}



extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }
    
    func performSearch() {
        if !searchBar.text!.isEmpty {
            searchBar.resignFirstResponder()
            
            dataTask?.cancel()
            
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = []
            
            /*
             URLSession
             */
            let url = iTunesURL(searchText: searchBar.text!, category: segmentedControl.selectedSegmentIndex)
            
            let session = URLSession.shared
            
            dataTask = session.dataTask(with: url,
                                            completionHandler: {data, response, error in
                                                if let error = error as NSError?, error.code == -999 {
                                                    //print("Cancelled")
                                                    return // cancelled
//                                                    //print("Failure! \(error.localizedDescription)")
                                                }
                                                else if let httpResponse = response as? HTTPURLResponse,
                                                        httpResponse.statusCode == 200 {
                                                        //print("Success! \(data!)")
                                                    if let data = data {
                                                        self.searchResults = self.parse(data: data)
                                                        self.searchResults.sort(by: <)
                                                        
                                                        DispatchQueue.main.async {
                                                            self.isLoading = false
                                                            self.tableView.reloadData()
                                                        }
                                                    }
                                                    
                                                    return
                                                }
                                                else {
                                                    //print("Failure! \(response!)")
                                                }
                                                
                                                // only error
                                                DispatchQueue.main.async {
                                                    self.hasSearched = false
                                                    self.isLoading = false
                                                    self.tableView.reloadData()
                                                    self.showNetworkError()
                                                }
                                            })
            dataTask?.resume()
        }
        
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}


extension SearchViewController {
    // MARK: - synchronous
    func iTunesURL(searchText: String, category: Int) -> URL {
        let kind: String
        
        switch category {
            case 1: kind = "musicTrack"
            case 2: kind = "software"
            case 3: kind = "ebook"
            default: kind = ""
        }
        
        let encodedText = searchText.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlUserAllowed)!
        
        let urlString = "https://itunes.apple.com/search?term=\(encodedText)&limit=200&entity=\(kind)"
        
        let url = URL(string: urlString)
        
        return url!
    }
    
    func parse(data: Data) -> [SearchResult] {
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(ResultArray.self, from: data)
            
            return result.results
        }
        catch {
            //print("JSON Error: \(error)")
            
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
            cell.configure(for: searchResult)
//            cell.nameLabel.text = searchResult.name
//
//            if searchResult.artist.isEmpty {
//                cell.artistNameLabel.text = "Unknown"
//            }
//            else {
//                cell.artistNameLabel.text = String(format: "%@ (%@)", searchResult.artist, searchResult.type)
//            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "ShowDetail", sender: indexPath)
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
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        guard landscapeVC == nil else {return}
        
        landscapeVC = storyboard!.instantiateViewController(withIdentifier: "LandscapeViewController") as? LandscapeViewController
        
        if let controller = landscapeVC {
            controller.searchResults = searchResults
            
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            view.addSubview(controller.view)
            addChild(controller)
            
            coordinator.animate(alongsideTransition: {_ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                
                if self.presentationController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: {_ in
                controller.didMove(toParent: self)
            })
            
//            controller.didMove(toParent: self)
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeVC {
            controller.willMove(toParent: nil)
            
//            controller.view.removeFromSuperview()
//            controller.removeFromParent()
//            landscapeVC = nil
            coordinator.animate(alongsideTransition: { _ in
                controller.view.alpha = 0
            }, completion: {_ in
                controller.view.removeFromSuperview()
                controller.removeFromParent()
                self.landscapeVC = nil
            })
        }
    }
}
