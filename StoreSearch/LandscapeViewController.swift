//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by aybjax on 6/8/21.
//

import UIKit

class LandscapeViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var searchResults = [SearchResult]()

    private var firstTime = true
    private var downloads = [URLSessionDownloadTask]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        view.backgroundColor = UIColor(patternImage: UIImage(named: "LandscapeBackground")!)
        pageControl.numberOfPages = 0
//        scrollView.contentSize = CGSize(width: 1000, height: 1000)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        scrollView.frame = safeFrame
        pageControl.frame = CGRect(x: safeFrame.origin.x,
                                   y: safeFrame.size.height - pageControl.frame.size.height,
                                   width: safeFrame.size.width,
                                   height: pageControl.frame.size.height)
        if firstTime {
            firstTime = false
            tileButtons(searchResults)
        }
    }
    
    deinit {
        print("deinit \(self)")
        
        for task in downloads {
            task.cancel()
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // Methods
    // =======
    
    private func tileButtons(_ searchResults: [SearchResult]) {
        var columnsPerPage = 6
        var rowPerPage = 3
        var itemWidth: CGFloat = 94
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 2
        var marginY: CGFloat = 20
        
        let viewWidth = scrollView.bounds.size.width
        
        switch viewWidth {
        case 568:
            // 4-inch
            break
        case 667:
            // 4.7-inch
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            // 5.5-inch
            columnsPerPage = 8
            rowPerPage = 4
            itemWidth = 92
            marginX = 0
        case 724:
            // iPhone X
            columnsPerPage = 8
            rowPerPage = 3
            itemWidth = 90
            itemHeight = 98
            marginX = 2
            marginY = 29
        default:
            break
        }
        
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth) / 2
        let paddingVert = (itemHeight - buttonHeight) / 2
        
        // add btn
        
        var row = 0
        var column = 0
        var x = marginX
        for (index, result) in searchResults.enumerated() {
            let button = UIButton(type: .custom)
            downloadImage(for: result, andPlaceOn: button)
            button.setBackgroundImage(UIImage(named: "LandscapeButton"), for: .normal)
//            button.setTitle("\(index)", for: .normal)
            button.frame = CGRect(x: x + paddingHorz,
                                  y: marginY + CGFloat(row) * itemHeight + paddingVert,
                                  width: buttonWidth, height: buttonHeight)
            
            scrollView.addSubview(button)
            
            row += 1
            
            if row == rowPerPage {
                row = 0; x += itemWidth; column += 1
                
                if column == columnsPerPage {
                    column = 0; x += marginX * 2
                    
                }
            }
            
        }
        
        // view content size
        let buttonsPerPage = columnsPerPage * rowPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        
        scrollView.contentSize = CGSize(
            width: CGFloat(numPages), height: scrollView.bounds.size.height)
        
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
    }

}

extension LandscapeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.size.width
        let page = Int((scrollView.contentOffset.x + width/2)/2)
        
        pageControl.currentPage = page
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseOut], animations: {
            self.scrollView.contentOffset = CGPoint(
                x: self.scrollView.bounds.size.width * CGFloat(sender.currentPage), y: 0)
        }, completion: nil)
    }
}


extension LandscapeViewController {
    private func downloadImage(for searchResult: SearchResult,
                               andPlaceOn button: UIButton) {
        if let url = URL(string: searchResult.imageSmall) {
            let task = URLSession.shared.downloadTask(with: url) {
                [weak button] url, response, error in
                
                if error == nil, let url = url,
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            }
            
            downloads.append(task)
            
            task.resume()
        }
    }
}
