//
//  FeedViewController.swift
//  Instagram
//
//  Created by Bryan Santos on 3/10/22.
//

import UIKit
import Parse
import AlamofireImage

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var posts = [PFObject]()
    let feedRefreshControl = UIRefreshControl()
    var numOfPosts = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        feedRefreshControl.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        tableView.refreshControl = feedRefreshControl
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getPosts()
    }
    
    @objc func getPosts() {
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
        query.limit = numOfPosts
        
        query.findObjectsInBackground { posts, error in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
                self.run(after: 1) {
                       self.feedRefreshControl.endRefreshing()
                }
            }
        }
    }
    
    func getMorePosts() {
        let query = PFQuery(className: "Posts")
        query.includeKey("author")
        numOfPosts += 5
        query.limit = numOfPosts
        
        query.findObjectsInBackground { posts, error in
            if posts != nil {
                self.posts = posts!
                self.tableView.reloadData()
                self.run(after: 1) {
                       self.feedRefreshControl.endRefreshing()
                }
            }
        }
    }
    
    func run(after wait: TimeInterval, closure: @escaping () -> Void) {
        let queue = DispatchQueue.main
        queue.asyncAfter(deadline: DispatchTime.now() + wait, execute: closure)
    }
    
    @IBAction func onSignOut(_ sender: Any) {
        PFUser.logOut()
        
        let main = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController = main.instantiateViewController(withIdentifier: "LoginViewController")
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let delegate = windowScene.delegate as? SceneDelegate else {return}
        
        delegate.window?.rootViewController = loginViewController
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
        let post = posts[indexPath.row]
        
        cell.captionLabel.text = post["caption"] as? String
        
        let user = post["author"] as! PFUser
        cell.usernameLabel.text = user.username
        
        let imageFile = post["image"] as! PFFileObject
        let imageURL = URL(string: imageFile.url!)
        cell.cellImageView.af.setImage(withURL: imageURL!)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 == posts.count {
            getMorePosts()
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

}
