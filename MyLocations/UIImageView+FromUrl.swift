import UIKit

extension UIImageView {
    func createFromUrl(url: String) {
        // set default image so that there is placeholder while
        // real image downloads asynchronously
        URLSession.shared.dataTask(with: NSURL(string: url)! as URL,
                                   completionHandler: { (data, response, error) -> Void in
            if error != nil {
                print(error!)
                return
            }
            DispatchQueue.main.async(execute: { () -> Void in
                print(response!)
                self.contentMode = .scaleAspectFill
                let image = UIImage(data: data!)
                self.image = image
            })

        }).resume()
    }
}
