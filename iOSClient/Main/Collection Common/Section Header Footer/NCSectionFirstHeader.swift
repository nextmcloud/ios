// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2018 Marino Faggiana
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import MarkdownKit
import NextcloudKit

protocol NCSectionFirstHeaderDelegate: AnyObject {
    func tapButtonSwitch(_ sender: Any)
    func tapButtonOrder(_ sender: Any)
    func tapButtonMore(_ sender: Any)
    func tapButtonTransfer(_ sender: Any)
    func tapRichWorkspace(_ sender: Any)
    func tapRecommendations(with metadata: tableMetadata, viewerTransitionSource: NCMediaViewerTransitionSource?)
}

extension NCSectionFirstHeaderDelegate {
    func tapButtonSwitch(_ sender: Any) {}
    func tapButtonOrder(_ sender: Any) {}
    func tapButtonMore(_ sender: Any) {}
}

class NCSectionFirstHeader: UICollectionReusableView, UIGestureRecognizerDelegate {

    @IBOutlet weak var buttonSwitch: UIButton!
    @IBOutlet weak var buttonOrder: UIButton!
    @IBOutlet weak var buttonMore: UIButton!
    @IBOutlet weak var buttonTransfer: UIButton!
    @IBOutlet weak var imageButtonTransfer: UIImageView!
    @IBOutlet weak var labelTransfer: UILabel!
    @IBOutlet weak var progressTransfer: UIProgressView!
    @IBOutlet weak var transferSeparatorBottom: UIView!
    @IBOutlet weak var textViewRichWorkspace: UITextView!
    @IBOutlet weak var labelSection: UILabel!
    @IBOutlet weak var viewTransfer: UIView!
    @IBOutlet weak var viewRichWorkspace: UIView!
    @IBOutlet weak var viewRecommendations: UIView!
    @IBOutlet weak var viewSection: UIView!
    @IBOutlet weak var viewButtonsView: UIView!
    @IBOutlet weak var viewSeparator: UIView!

    @IBOutlet weak var viewTransferHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewButtonsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewSeparatorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRichWorkspaceHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewRecommendationsHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewRecommendationsLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var viewRecommendationsTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var transferSeparatorBottomHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var collectionViewRecommendations: UICollectionView!
    @IBOutlet weak var labelRecommendations: UILabel!

    private weak var delegate: NCSectionFirstHeaderDelegate?
    private let utility = NCUtility()
    private var markdownParser = MarkdownParser()
    private let global = NCGlobal.shared
    private var richWorkspaceText: String?
    private let richWorkspaceGradient: CAGradientLayer = CAGradientLayer()
    private var recommendations: [tableRecommendedFiles] = []
    private var viewController: UIViewController?
    private weak var parentCollectionView: UICollectionView?
    private var sceneIdentifier: String = ""
    private var recommendationsIdentity: [String] = []
    private var contentRequestID = UUID()

#if !EXTENSION
    @MainActor
    internal var controller: NCMainTabBarController? {
        viewController?.tabBarController as? NCMainTabBarController
    }
#endif

    override func awakeFromNib() {
        super.awakeFromNib()

        // The recommendations carousel is intentionally allowed to extend beyond
        // the safe-area-sized parent collection view.
        clipsToBounds = false

        //
        // RichWorkspace
        //
        richWorkspaceGradient.startPoint = CGPoint(x: 0, y: 0.8)
        richWorkspaceGradient.endPoint = CGPoint(x: 0, y: 0.9)
        viewRichWorkspace.layer.addSublayer(richWorkspaceGradient)
        backgroundColor = .clear
        
        //Button
        buttonSwitch.setImage(UIImage(systemName: "list.bullet")!.image(color: NCBrandColor.shared.iconColor, size: 25), for: .normal)

        buttonOrder.setTitle("", for: .normal)
        buttonOrder.setTitleColor(NCBrandColor.shared.brand, for: .normal)
        buttonMore.setImage(UIImage(named: "more")!.image(color: NCBrandColor.shared.iconColor, size: 25), for: .normal)

        // Gradient
//        gradient.startPoint = CGPoint(x: 0, y: 0.8)
//        gradient.endPoint = CGPoint(x: 0, y: 0.9)
//        viewRichWorkspace.layer.addSublayer(gradient)

        let tap = UITapGestureRecognizer(target: self, action: #selector(touchUpInsideViewRichWorkspace(_:)))
        tap.delegate = self
        viewRichWorkspace?.addGestureRecognizer(tap)
        viewSeparatorHeightConstraint.constant = 0.5
        viewSeparator.backgroundColor = .separator
        
        markdownParser = MarkdownParser(font: UIFont.systemFont(ofSize: 15), color: NCBrandColor.shared.textColor)
        markdownParser.header.font = UIFont.systemFont(ofSize: 25)
        if let richWorkspaceText = richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(richWorkspaceText)
        }

        //
        // Recommendations
        //
        viewRecommendationsHeightConstraint.constant = 0
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.scrollDirection = .horizontal

        collectionViewRecommendations.collectionViewLayout = layout
        collectionViewRecommendations.contentInsetAdjustmentBehavior = .never
        collectionViewRecommendations.register(UINib(nibName: "NCRecommendationsCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        labelRecommendations.text = NSLocalizedString("_recommended_files_", comment: "")

        //
        // Section
        //
        labelSection.text = ""
        viewSectionHeightConstraint.constant = 0

        buttonTransfer.backgroundColor = .clear
        buttonTransfer.setImage(nil, for: .normal)
        buttonTransfer.layer.cornerRadius = 6
        buttonTransfer.layer.masksToBounds = true
        imageButtonTransfer.image = UIImage(systemName: "stop.circle")
        imageButtonTransfer.tintColor = .white
        labelTransfer.text = ""
        progressTransfer.progress = 0
        progressTransfer.tintColor = NCBrandColor.shared.brand
        progressTransfer.trackTintColor = NCBrandColor.shared.brand.withAlphaComponent(0.2)
        transferSeparatorBottom.backgroundColor = .separator
        transferSeparatorBottomHeightConstraint.constant = 0.5
    }

    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)

        richWorkspaceGradient.frame = viewRichWorkspace.bounds
        setRichWorkspaceColor()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateRecommendationsLayout()
    }

    private func updateRecommendationsLayout() {
        guard let viewController else { return }

        let safeAreaInsets = viewController.view.safeAreaInsets
        viewRecommendationsLeadingConstraint.constant = -safeAreaInsets.left
        viewRecommendationsTrailingConstraint.constant = -safeAreaInsets.right

        // Keep the final recommendation clear of the safe-area overlay when
        // scrolled all the way to the end of the carousel.
        if collectionViewRecommendations.contentInset.right != safeAreaInsets.right {
            var contentInset = collectionViewRecommendations.contentInset
            contentInset.right = safeAreaInsets.right
            collectionViewRecommendations.contentInset = contentInset
        }

        if collectionViewRecommendations.horizontalScrollIndicatorInsets.right != safeAreaInsets.right {
            var horizontalScrollIndicatorInsets = collectionViewRecommendations.horizontalScrollIndicatorInsets
            horizontalScrollIndicatorInsets.right = safeAreaInsets.right
            collectionViewRecommendations.horizontalScrollIndicatorInsets = horizontalScrollIndicatorInsets
        }
    }

    private func setParentCollectionViewClipping(_ clipsToBounds: Bool) {
        parentCollectionView?.clipsToBounds = clipsToBounds
    }

    func setContent(heightHeaderRichWorkspace: CGFloat,
                    richWorkspaceText: String?,
                    heightHeaderRecommendations: CGFloat,
                    recommendations: [tableRecommendedFiles],
                    heightHeaderSection: CGFloat,
                    sectionText: String?,
                    viewController: UIViewController?,
                    parentCollectionView: UICollectionView?,
                    sceneItentifier: String,
                    delegate: NCSectionFirstHeaderDelegate?) {
        viewRichWorkspaceHeightConstraint.constant = heightHeaderRichWorkspace
        viewRecommendationsHeightConstraint.constant = heightHeaderRecommendations
        viewSectionHeightConstraint.constant = heightHeaderSection
        
        if let richWorkspaceText, richWorkspaceText != self.richWorkspaceText {
            textViewRichWorkspace.attributedText = markdownParser.parse(richWorkspaceText)
            self.richWorkspaceText = richWorkspaceText
        }
        setRichWorkspaceColor()
        let accountChanged = self.recommendations.first?.account != recommendations.first?.account
        contentRequestID = UUID()
        let requestID = contentRequestID
        self.recommendations = recommendations
        self.labelSection.text = sectionText
        self.viewController = viewController
        self.parentCollectionView = parentCollectionView
        self.sceneIdentifier = sceneItentifier
        self.delegate = delegate

        let recommendationsVisible = heightHeaderRecommendations != 0 && !recommendations.isEmpty
        setParentCollectionViewClipping(!recommendationsVisible)
        updateRecommendationsLayout()

        if heightHeaderRichWorkspace != 0, let richWorkspaceText, !richWorkspaceText.isEmpty {
            viewRichWorkspace.isHidden = false
        } else {
            viewRichWorkspace.isHidden = true
        }
    }
    
    func setRichWorkspaceText(_ text: String?) {
        guard let text = text else { return }

        if recommendationsVisible {
            viewRecommendations.isHidden = false
        } else {
            var image: UIImage?
            if let ocId,
               let metadata = NCManageDatabase.shared.getMetadataFromOcId(ocId) {
                image = utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: NCGlobal.shared.previewExt256)?.darken()
                if image == nil {
                    image = UIImage(named: metadata.iconName)
                    buttonTransfer.backgroundColor = .lightGray
                } else {
                    buttonTransfer.backgroundColor = .clear
                }
            }
            viewTransferHeightConstraint.constant = NCGlobal.shared.heightHeaderTransfer
            if let progress {
                progressTransfer.progress = progress
            }
        }

//        if heightHeaderSection == 0 {
//            viewSection.isHidden = true
//        } else {
//            viewSection.isHidden = false
//        }

        if accountChanged {
            recommendationsIdentity = []
            collectionViewRecommendations.reloadData()
        }

#if EXTENSION
        self.collectionViewRecommendations.reloadData()
#else
        Task { [weak self] in
            guard let self else { return }

            let isPause = await (viewController as? NCCollectionViewCommon)?
                .debouncerReloadDataSource
                .isPausedNow() ?? false

            guard !isPause, self.contentRequestID == requestID else {
                return
            }

            let fileIds = recommendations.map(\.id)
            let metadatas = await NCManageDatabase.shared.getMetadatasFromFileIdsAsync(fileIds, account: recommendations.first?.account ?? "")
            let etagsByFileId = Dictionary(
                metadatas.map { ($0.fileId, $0.etag) },
                uniquingKeysWith: { current, _ in current }
            )
            let newRecommendationsIdentity = recommendations.map {
                "\($0.account)|\($0.id)|\($0.reason)|\(etagsByFileId[$0.id] ?? "")"
            }

            guard self.contentRequestID == requestID,
                  self.recommendationsIdentity != newRecommendationsIdentity else {
                return
            }

            self.recommendationsIdentity = newRecommendationsIdentity
            self.collectionViewRecommendations.reloadData()
        }
#endif
    }

    // MARK: - RichWorkspace

    private func setRichWorkspaceColor() {
        if traitCollection.userInterfaceStyle == .dark {
            richWorkspaceGradient.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor.black.cgColor]
        } else {
            richWorkspaceGradient.colors = [UIColor(white: 1, alpha: 0).cgColor, UIColor.white.cgColor]
        }
    }
        
    // MARK: - Action
    
    @IBAction func touchUpInsideSwitch(_ sender: Any) {
        delegate?.tapButtonSwitch(sender)
    }

    @IBAction func touchUpInsideOrder(_ sender: Any) {
        delegate?.tapButtonOrder(sender)
    }
    
    @IBAction func touchUpInsideMore(_ sender: Any) {
        delegate?.tapButtonMore(sender)
    }

    @IBAction func touchUpTransfer(_ sender: Any) {
       delegate?.tapButtonTransfer(sender)
    }

    @objc func touchUpInsideViewRichWorkspace(_ sender: Any) {
        delegate?.tapRichWorkspace(sender)
    }
}

extension NCSectionFirstHeader: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.recommendations.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let recommendedFile = self.recommendations[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) as? NCRecommendationsCell else {
            fatalError("Unable to dequeue NCRecommendationsCell")
        }

        cell.representedFileId = recommendedFile.id
        cell.representedAccount = recommendedFile.account
        cell.imageRequestID = UUID()
        cell.metadata = nil
        let imageRequestID = cell.imageRequestID
        cell.labelInfo.text = recommendedFile.reason
        cell.delegate = self
        cell.image.image = nil
        cell.image.contentMode = .scaleAspectFit
        cell.setImageCorner(withBorder: false)

        let fileId = recommendedFile.id
        let account = recommendedFile.account

        Task { [weak self, weak cell] in
            guard let self,
                  let metadata = await NCManageDatabase.shared.getMetadataFromFileIdAsync(fileId, account: account),
                  !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let cell,
                      cell.representedFileId == fileId,
                      cell.representedAccount == account,
                      cell.imageRequestID == imageRequestID else {
                    return
                }

                cell.metadata = metadata
                cell.setBidiSafeFilename(
                    metadata.fileNameView,
                    isDirectory: metadata.directory,
                    titleLabel: cell.labelFilename,
                    extensionLabel: cell.labelExtensionFilename
                )

                let hasDocumentPreview = metadata.hasPreview &&
                metadata.classFile == NKTypeClassFile.document.rawValue

                cell.setImageCorner(withBorder: hasDocumentPreview)
            }

            if metadata.directory {
                let icon = self.utility.loadImage(
                    named: metadata.iconName,
                    useTypeIconFile: true,
                    account: metadata.account
                )

                await MainActor.run {
                    guard let cell,
                          cell.representedFileId == fileId,
                          cell.representedAccount == account,
                          cell.imageRequestID == imageRequestID else {
                        return
                    }

                    cell.image.image = icon
                    cell.image.contentMode = .scaleAspectFit
                }

                return
            }

            if let image = self.utility.getImage(
                ocId: metadata.ocId,
                etag: metadata.etag,
                ext: self.global.previewExt512,
                userId: metadata.userId,
                urlBase: metadata.urlBase
            ) {
                await MainActor.run {
                    guard let cell,
                          cell.representedFileId == fileId,
                          cell.representedAccount == account,
                          cell.imageRequestID == imageRequestID else {
                        return
                    }

                    cell.image.image = image
                    cell.image.contentMode = .scaleAspectFill
                }

                return
            }

            let icon = self.utility.loadImage(
                named: metadata.iconName,
                useTypeIconFile: true,
                account: metadata.account
            )

            await MainActor.run {
                guard let cell,
                      cell.representedFileId == fileId,
                      cell.representedAccount == account,
                      cell.imageRequestID == imageRequestID else {
                    return
                }

                cell.image.image = icon
                cell.image.contentMode = .scaleAspectFit
            }

            let result = await NextcloudKit.shared.downloadPreviewAsync(
                fileId: fileId,
                etag: metadata.etag,
                account: metadata.account
            )

            guard result.error == .success,
                  let data = result.responseData?.data,
                  let image = utility.createImageFileFrom(
                    data: data,
                    ocId: metadata.ocId,
                    etag: metadata.etag,
                    ext: self.global.previewExt512,
                    userId: metadata.userId,
                    urlBase: metadata.urlBase
                  ) else {
                return
            }

            await MainActor.run {
                guard let cell,
                      cell.representedFileId == fileId,
                      cell.representedAccount == account,
                      cell.imageRequestID == imageRequestID else {
                    return
                }

                cell.image.contentMode = .scaleAspectFill

                if metadata.classFile == NKTypeClassFile.document.rawValue {
                    cell.setImageCorner(withBorder: true)
                }

                UIView.transition(
                    with: cell.image,
                    duration: 0.25,
                    options: .transitionCrossDissolve
                ) {
                    cell.image.image = image
                }
            }
        }

        return cell
    }
}

extension NCSectionFirstHeader: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let recommendedFiles = self.recommendations[indexPath.row]
        guard let metadata = NCManageDatabase.shared.getMetadataFromFileId(recommendedFiles.id, account: recommendedFiles.account),
            let cell = collectionView.cellForItem(at: indexPath) as? NCRecommendationsCell else {
            return
        }
        let viewerTransitionSource = cell.viewerTransitionSource()

        self.delegate?.tapRecommendations(with: metadata, viewerTransitionSource: viewerTransitionSource)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let recommendedFiles = self.recommendations[indexPath.row]
        guard let metadata = NCManageDatabase.shared.getMetadataFromFileId(recommendedFiles.id, account: recommendedFiles.account),
              metadata.classFile != NKTypeClassFile.url.rawValue,
              let viewController else {
            return nil
        }
        let identifier = indexPath as NSCopying
        let image = utility.getImage(ocId: metadata.ocId, etag: metadata.etag, ext: NCGlobal().previewExt1024)

#if EXTENSION
        return nil
#else
        return UIContextMenuConfiguration(identifier: identifier, previewProvider: {
            return NCViewerProviderContextMenu(metadata: metadata, image: image, sceneIdentifier: self.sceneIdentifier)
        }, actionProvider: { _ in
            let cell = collectionView.cellForItem(at: indexPath)
            let contextMenu = NCContextMenuMain(metadata: metadata.detachedCopy(), viewController: viewController, controller: self.controller, sender: cell)
            return contextMenu.viewMenu()
        })
#endif
    }
}

extension NCSectionFirstHeader: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellHeight = collectionView.bounds.height - 20

        return CGSize(width: cellHeight, height: cellHeight)
    }
}

extension NCSectionFirstHeader: NCRecommendationsCellDelegate {
    func openContextMenu(with metadata: tableMetadata?, button: UIButton, sender: Any) {
#if !EXTENSION
        guard let viewController = self.viewController, let metadata else {
            button.menu = nil
            return
        }
        button.menu = NCContextMenuMain(metadata: metadata, viewController: viewController, controller: self.controller, sender: sender).viewMenu()
#endif
    }

    func onMenuIntent(with metadata: tableMetadata?) {
#if !EXTENSION
        Task {
            let collectionViewCommon = (self.viewController as? NCCollectionViewCommon)
            await collectionViewCommon?.debouncerReloadData.pause()
        }
#endif
    }
}
