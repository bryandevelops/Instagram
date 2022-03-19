//
//  FeedViewController.swift
//  Instagram
//
//  Created by Bryan Santos on 3/10/22.
//

import UIKit
import Parse
import AlamofireImage
import MessageInputBar

class FeedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessageInputBarDelegate {

    @IBOutlet weak var tableView: UITableView!
    var posts = [PFObject]()
    let feedRefreshControl = UIRefreshControl()
    var numOfPosts = 10
    let commentBar = MessageInputBar()
    var isShowingCommentBar = false
    var selectedPost: PFObject!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        feedRefreshControl.addTarget(self, action: #selector(getPosts), for: .valueChanged)
        tableView.refreshControl = feedRefreshControl
        
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self, selector: #selector(hideKeyboard(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        commentBar.inputTextView.placeholder = "Add a comment..."
        commentBar.sendButton.title = "Post"
        commentBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getPosts()
    }
    
    override var inputAccessoryView: UIView? {
        return commentBar
    }
    
    override var canBecomeFirstResponder: Bool {
        return isShowingCommentBar
    }
    
    @objc func hideKeyboard(note: Notification) {
        commentBar.inputTextView.text = nil
        isShowingCommentBar = false
        becomeFirstResponder()
    }
    
    @objc func getPosts() {
        let query = PFQuery(className: "Posts")
        query.includeKeys(["author", "comments", "comments.author"])
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
        query.includeKeys(["author", "comments", "comments.author"])
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
        let post = posts[section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        return comments.count + 2 //One for the photo's row, and a second for the Add a comment... row
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == 0 { // The very first row of each section represents the Post's photo
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostTableViewCell") as! PostTableViewCell
            
            cell.captionLabel.text = post["caption"] as? String
            
            let user = post["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            let imageFile = post["image"] as! PFFileObject
            let imageURL = URL(string: imageFile.url!)
            cell.cellImageView.af.setImage(withURL: imageURL!)
            
            return cell
        } else if indexPath.row <= comments.count { // Every other row in a section is for the Post's comments
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentTableViewCell") as! CommentTableViewCell
            
            let comment = comments[indexPath.row - 1] // Row 0 is for the Photo, so the comments start at Row 1. However, if we're indexing into the comment array, we need to index beginning at 0
            cell.commentLabel.text = comment["text"] as? String
            
            let user = comment["author"] as! PFUser
            cell.usernameLabel.text = user.username
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCommentTableViewCell")!
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section + 1 == posts.count {
            getMorePosts()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = posts[indexPath.section]
        let comments = (post["comments"] as? [PFObject]) ?? []
        
        if indexPath.row == comments.count + 1 {
            selectedPost = post
            isShowingCommentBar = true
            becomeFirstResponder()
            commentBar.inputTextView.becomeFirstResponder()
        }
    }
    
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        let comment = PFObject(className: "Comments")
        
        comment["text"] = text
        comment["post"] = selectedPost
        comment["author"] = PFUser.current()

        selectedPost.add(comment, forKey: "comments")
        selectedPost.saveInBackground { success, error in
            if success {
                print("Comment added")
            } else {
                print("\(error?.localizedDescription ?? "Error adding comment")")
            }
        }
        tableView.reloadData()
        
        commentBar.inputTextView.text = nil
        isShowingCommentBar = false
        becomeFirstResponder()
        commentBar.inputTextView.resignFirstResponder()
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
