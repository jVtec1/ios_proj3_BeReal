//
//  CommentsViewController.swift
//  BeReal
//
//  Created by Andy Espinoza on 3/1/26.
//

import Foundation
import UIKit
import ParseSwift

final class CommentsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var commentTextField: UITextField!
    @IBOutlet private weak var sendButton: UIButton!

    var post: Post!

    private var comments: [Comment] = [] {
        didSet { tableView.reloadData() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Comments"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive

        // Optional: nicer dynamic row heights
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension

        queryComments()
    }

    private func queryComments() {
        guard let postObjectId = post.objectId else { return }

        // Use a pointer-only Post to avoid any issues with equality checks
        var postPointer = Post()
        postPointer.objectId = postObjectId

        guard let query = try? Comment.query()
            .include("user")
            .include("post")
            .where("post" == postPointer)
            .order([.ascending("createdAt")])
            .limit(200)
        else {
            showAlert(description: "Failed to create query.")
            return
        }

        query.find { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let comments):
                    self?.comments = comments
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    @IBAction private func onSendTapped(_ sender: Any) {
        view.endEditing(true)

        guard let currentUser = User.current else {
            showAlert(description: "You must be logged in to comment.")
            return
        }

        let trimmed = (commentTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let postObjectId = post.objectId else { return }

        var postPointer = Post()
        postPointer.objectId = postObjectId

        var newComment = Comment()
        newComment.text = trimmed
        newComment.user = currentUser
        newComment.post = postPointer

//        // (Optional) Basic ACL: public read, only author can write
//        if let userId = currentUser.objectId {
//            var acl = ParseACL()
//            acl.setReadAccess(userId: userId, value: true)
//            acl.setWriteAccess(userId: userId, value: true)
//            acl.publicRead = true
//            acl.publicWrite = false
//            newComment.ACL = acl
//        }

        sendButton.isEnabled = false

        newComment.save { [weak self] result in
            DispatchQueue.main.async {
                self?.sendButton.isEnabled = true

                switch result {
                case .success(let saved):
                    // Clear UI + update local list immediately
                    self?.commentTextField.text = nil
                    self?.comments.append(saved)
                    self?.scrollToBottom()
                case .failure(let error):
                    self?.showAlert(description: error.localizedDescription)
                }
            }
        }
    }

    private func scrollToBottom() {
        guard !comments.isEmpty else { return }
        let lastRow = IndexPath(row: comments.count - 1, section: 0)
        tableView.scrollToRow(at: lastRow, at: .bottom, animated: true)
    }
}

extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Use a basic cell style if you don’t want a custom CommentCell yet
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "CommentCell")

        let comment = comments[indexPath.row]
        let username = comment.user?.username ?? "Unknown"
        cell.textLabel?.text = username
        cell.detailTextLabel?.text = comment.text
        cell.detailTextLabel?.numberOfLines = 0
        cell.selectionStyle = .none

        return cell
    }
}
