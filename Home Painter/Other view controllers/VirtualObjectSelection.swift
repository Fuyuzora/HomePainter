//
//  VirtualObjectSelection.swift
//  Home Painter
//
//  Created by Robert Wan on 2019-01-28.
//  Copyright © 2019 App. All rights reserved.
//

import UIKit
import ARKit

// Object cell

class ObjectCell: UITableViewCell {
    static let reuseIdentifier = "ObjectCell"
    
    @IBOutlet weak var objectTitleLabel: UILabel!
    @IBOutlet weak var objectImageView: UIImageView!
    @IBOutlet weak var vibrancyView: UIVisualEffectView!
    
    // Assign model and image name of the model
    var modelName = "" {
        didSet {
            objectTitleLabel.text = modelName.capitalized
            objectImageView.image = UIImage(named: modelName)
        }
    }
}

// Virtual object selection view controller delegate
// A protocol reporting which object is selected
protocol VirtualObjectSelectionViewControllerDelegate:class {
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, didSelectObject: virtualObject)
    func virtualObjectSelectionViewController(_ selectionViewController: VirtualObjectSelectionViewController, DidDeselectObject: virtualObject)
}

class VirtualObjectSelectionViewController: UITableViewController {
    
    // A collection of virtual objects to select from
    var virtualObjects = [virtualObject]()
    
    // The row index of the currectly selected virtual object
    var selectedVirtualObjectRows = IndexSet()
    
    // The rows of virtual objects that currently allowed to be placed
    var enabledVirtualObjectRows = Set<Int>()
    
    // Respond to delegate
    weak var delegate: VirtualObjectSelectionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // UI table view delegate
    override func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else {return}
        
        let object = virtualObjects[indexPath.row]
        
        // Check if current row is selected, if so deselect it
        if selectedVirtualObjectRows.contains(indexPath.row) {
            delegate?.virtualObjectSelectionViewController(self, DidDeselectObject: object)
        } else {
            delegate?.virtualObjectSelectionViewController(self, didSelectObject: object)
        }
    }
    
    // UI table view data source
    override func tableView (_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return virtualObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ObjectCell.reuseIdentifier, for: indexPath) as? ObjectCell else {
            fatalError("Expected `\(ObjectCell.self)` type for reuseIdentifier \(ObjectCell.reuseIdentifier). Check the configuration in main.storyboard")
        }
        
        cell.modelName = virtualObjects[indexPath.row].modelName
        
        if selectedVirtualObjectRows.contains(indexPath.row) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        if cellIsEnabled {
            cell.vibrancyView.alpha = 1.0
        } else {
            cell.vibrancyView.alpha = 0.1
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cellIsEnabled = enabledVirtualObjectRows.contains(indexPath.row)
        guard cellIsEnabled else { return }

        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = .clear
    }
}
