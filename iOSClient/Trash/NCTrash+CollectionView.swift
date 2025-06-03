//
//  NCTrash+CollectionView.swift
//  Nextcloud
//
//  Created by Henrik Storch on 18.01.22.
//  Copyright © 2022 Henrik Storch. All rights reserved.
//
//  Author Henrik Storch <henrik.storch@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import RealmSwift
import Foundation

// MARK: UICollectionViewDelegate
extension NCTrash: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let tableTrash = datasource[indexPath.item]

        guard let resultTableTrash = datasource?[indexPath.item] else { return }
        let resultTableTrash = datasource[indexPath.item]

        guard !isEditMode else {
            if let index = fileSelect.firstIndex(of: resultTableTrash.fileId) {
                fileSelect.remove(at: index)
            } else {
                fileSelect.append(resultTableTrash.fileId)
            }
            collectionView.reloadItems(at: [indexPath])
            tabBarSelect.update(selectOcId: fileSelect)
            setNavigationRightItems()
            return
        }

        if resultTableTrash.directory,
           let ncTrash: NCTrash = UIStoryboard(name: "NCTrash", bundle: nil).instantiateInitialViewController() as? NCTrash {
            ncTrash.trashPath = tableTrash.filePath + tableTrash.fileName
            ncTrash.titleCurrentFolder = tableTrash.trashbinFileName
            ncTrash.filePath = resultTableTrash.filePath + resultTableTrash.fileName
            ncTrash.titleCurrentFolder = resultTableTrash.trashbinFileName
            ncTrash.filename = resultTableTrash.fileName
            self.navigationController?.pushViewController(ncTrash, animated: true)
        }
    }
}

// MARK: UICollectionViewDataSource
extension NCTrash: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emptyDataSet?.numberOfItemsInSection(datasource.count, section: section)
        setNavigationRightItems()
        return datasource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let tableTrash = datasource[indexPath.item]
        var image: UIImage?

        if tableTrash.iconName.isEmpty {
            image = UIImage(named: "file")
        } else {
            image = UIImage(named: tableTrash.iconName)
        setNavigationRightItems()
        return datasource?.count ?? 0
        let numberOfItems = datasource.count
        emptyDataSet?.numberOfItemsInSection(numberOfItems, section: section)
        setNavigationRightItems()
        return numberOfItems
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var image: UIImage?
        var cell: NCTrashCellProtocol & UICollectionViewCell

        if layoutForView?.layout == NCGlobal.shared.layoutList {
            let listCell = (collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as? NCTrashListCell)!
            listCell.delegate = self
            cell = listCell
        } else {
            let gridCell = (collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as? NCTrashGridCell)!
            gridCell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCImageCache.shared.getImageButtonMore())
            gridCell.delegate = self
            cell = gridCell
        }
        
        let resultTableTrash = datasource[indexPath.item]
        cell.imageItem.contentMode = .scaleAspectFit

        if resultTableTrash.iconName.isEmpty {
            image = NCImageCache.shared.getImageFile()
        } else {
            image = UIImage(named: resultTableTrash.iconName)
        }

        if let imageIcon = utility.getImage(ocId: resultTableTrash.fileId, etag: resultTableTrash.fileName, ext: NCGlobal.shared.previewExt512) {
            image = imageIcon
            cell.imageItem.contentMode = .scaleAspectFill
        } else {
            if resultTableTrash.hasPreview {
                if NCNetworking.shared.downloadThumbnailTrashQueue.operations.filter({ ($0 as? NCOperationDownloadThumbnailTrash)?.fileId == resultTableTrash.fileId }).isEmpty {
                    NCNetworking.shared.downloadThumbnailTrashQueue.addOperation(NCOperationDownloadThumbnailTrash(fileId: resultTableTrash.fileId, fileName: resultTableTrash.fileName, account: session.account, collectionView: collectionView))
                }
            }
        }

        var cell: NCTrashCellProtocol & UICollectionViewCell

        if layoutForView?.layout == NCGlobal.shared.layoutList {
            guard let listCell = collectionView.dequeueReusableCell(withReuseIdentifier: "listCell", for: indexPath) as? NCTrashListCell else { return UICollectionViewCell() }
            listCell.delegate = self
            cell = listCell
        } else {
            // GRID
            guard let gridCell = collectionView.dequeueReusableCell(withReuseIdentifier: "gridCell", for: indexPath) as? NCTrashGridCell else { return UICollectionViewCell() }
            gridCell.setButtonMore(named: NCGlobal.shared.buttonMoreMore, image: NCImageCache.images.buttonMore)
            gridCell.delegate = self
            cell = gridCell
        }

        cell.indexPath = indexPath
        cell.setupCellUI(tableTrash: tableTrash, image: image)
        cell.selected(selectOcId.contains(tableTrash.fileId), isEditMode: isEditMode)

        return cell
    }

    func setTextFooter(datasource: [tableTrash]) -> String {

        cell.account = resultTableTrash.account
        cell.objectId = resultTableTrash.fileId
        cell.setupCellUI(tableTrash: resultTableTrash, image: image)
        cell.selected(selectOcId.contains(resultTableTrash.fileId), isEditMode: isEditMode, account: resultTableTrash.account)
        return cell
    }

    func setTextFooter(datasource: [tableTrash]) -> String {
        var folders: Int = 0, foldersText = ""
        var files: Int = 0, filesText = ""
        var size: Int64 = 0
        var text = ""

        for record: tableTrash in datasource {
            if record.directory {
                folders += 1
            } else {
                files += 1
                size += record.size
            }
        }

        if folders > 1 {
            foldersText = "\(folders) " + NSLocalizedString("_folders_", comment: "")
        } else if folders == 1 {
            foldersText = "1 " + NSLocalizedString("_folder_", comment: "")
        }

        if files > 1 {
            filesText = "\(files) " + NSLocalizedString("_files_", comment: "") + " " + utilityFileSystem.transformedSize(size)
        } else if files == 1 {
            filesText = "1 " + NSLocalizedString("_file_", comment: "") + " " + utilityFileSystem.transformedSize(size)
        }

        if foldersText.isEmpty {
            text = filesText
        } else if filesText.isEmpty {
            text = foldersText
        } else {
            text = foldersText + ", " + filesText
        }

        return text
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {

            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionHeaderMenu", for: indexPath) as? NCSectionHeaderMenu
            else { return UICollectionReusableView() }

            if layoutForView?.layout == NCGlobal.shared.layoutGrid {
                header.setImageSwitchList()
                header.buttonSwitch.accessibilityLabel = NSLocalizedString("_list_view_", comment: "")
            } else {
                header.setImageSwitchGrid()
                header.buttonSwitch.accessibilityLabel = NSLocalizedString("_grid_view_", comment: "")
            }
            
            header.delegate = self
            header.setStatusButtonsView(enable: !datasource.isEmpty)
            header.setStatusButtonsView(enable: !(datasource?.isEmpty ?? false))
            header.setSortedTitle(layoutForView?.titleButtonHeader ?? "")
            header.setButtonsView(height: NCGlobal.shared.heightButtonsView)
            header.setRichWorkspaceHeight(0)
            header.setSectionHeight(0)
            header.setViewTransfer(isHidden: true)
            
            return header
            
        } else {
            guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "sectionFooter", for: indexPath) as? NCSectionFooter
            else { return UICollectionReusableView() }
            
            guard let datasource else { return footer }
            footer.setTitleLabel(setTextFooter(datasource: datasource))
            footer.separatorIsHidden(true)
            
            return footer
        }
    }
}

// MARK: UICollectionViewDelegateFlowLayout
extension NCTrash: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if datasource.isEmpty {
            let height = utility.getHeightHeaderEmptyData(view: view, portraitOffset: 0, landscapeOffset: -20)
            return CGSize(width: collectionView.frame.width, height: height)
        }
        return CGSize(width: collectionView.frame.width, height: NCGlobal.shared.heightButtonsView)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 85)
    }
}
