import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .medium
  formatter.timeStyle = .short
  return formatter
}()

class LocationDetailsViewController: UITableViewController {

    @IBOutlet weak var politicianCell: UITableViewCell!
    @IBOutlet weak var politicianImage: UIImageView!
    @IBOutlet weak var politicianName: UILabel!
    @IBOutlet weak var phoneNumber: UILabel!

  // when district is set, set lots of variables
    var district: District? {
        didSet {
            if let district = district {
               print(district)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        let backButton: UIBarButtonItem = UIBarButtonItem(title: "Back",
                                                          style: .plain,
                                                          target: self,
                                                          action: #selector(back))
        self.navigationItem.leftBarButtonItem = backButton;
        super.viewWillAppear(animated);
    }

    func back() {
        self.dismiss(animated: true, completion: nil)
    }

  override func viewDidLoad() {
    super.viewDidLoad()

    // configure views here
    if let district = self.district {
        let photo_url = district.getFullURL()
        self.navigationItem.title = district.getFullName()
        politicianImage.image = UIImage(named: "Pin")
        politicianImage.createFromUrl(url: photo_url)
        politicianName.text = district.politician_name
        phoneNumber.text = district.phone_number
    }

    // make the backgrounds pretty in black
    tableView.backgroundColor = UIColor.black
    tableView.separatorColor = UIColor(white: 1.0, alpha: 0.2)
    tableView.indicatorStyle = .white
    
    // -------------------------------------------------

  }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PoliticianDetail" {

            // create district from json + attach new district to target controller
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! PoliticianDetailViewController
            if let district = district {
                controller.politician_url = district.politician_url
            }
        } else if segue.identifier == "DistrictDetail" {
            // create district from json + attach new district to target controller
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! PoliticianDetailViewController
            if let district = district {
                controller.politician_url = district.district_url
            }
        }
    }

    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Current Representative"
        } else if section == 1 {
            return "District Information"
        } else {
            return ""
        }
    }

    override func tableView(_ tableView: UITableView,
                            willDisplayHeaderView view: UIView,
                            forSection section: Int) {
        view.tintColor = UIColor.red
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = UIColor.white
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {

        if indexPath.row == 0 && indexPath.section == 0 {
            self.performSegue(withIdentifier: "PoliticianDetail", sender:self)
        } else if indexPath.row == 0 && indexPath.section == 1 {
            print("Calling number \(district?.phone_number)!")
            guard let number = URL(string: "telprompt://" + (district?.phone_number)!) else { return }
            UIApplication.shared.open(number, options: [:], completionHandler: nil)

        } else if indexPath.row == 1 && indexPath.section == 1 {
            self.performSegue(withIdentifier: "DistrictDetail", sender:self)
        }

    }


  func format(date: Date) -> String {
    return dateFormatter.string(from: date)
  }

}
