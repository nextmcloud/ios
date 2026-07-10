// SPDX-FileCopyrightText: Nextcloud GmbH
// SPDX-FileCopyrightText: 2019 Marino Faggiana
// SPDX-FileCopyrightText: 2019 Philippe Weidmann
// SPDX-License-Identifier: GPL-3.0-or-later

import UIKit
import NextcloudKit

class NCIntroViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var buttonSignUp: UIButton!
    @IBOutlet weak var buttonHost: UIButton!
    @IBOutlet weak var introCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contstraintBottomLoginButton: NSLayoutConstraint!

    weak var delegate: NCIntroViewController?
    // Controller
    var controller: NCMainTabBarController?

    private let appDelegate = (UIApplication.shared.delegate as? AppDelegate)!
//    private let titles = [NSLocalizedString("_intro_1_title_", comment: ""), NSLocalizedString("_intro_2_title_", comment: ""), NSLocalizedString("_intro_3_title_", comment: ""), NSLocalizedString("_intro_4_title_", comment: "")]
//    private var images = [UIImage(named: "intro1"), UIImage(named: "intro2"), UIImage(named: "intro3"), UIImage(named: "intro4")]
    private let titles = [NSLocalizedString("", comment: ""), NSLocalizedString("", comment: ""), NSLocalizedString("", comment: "")]
    private var images: [UIImage?] = []
    private var timer: Timer?
    private var textColor: UIColor = .white
    private var textColorOpponent: UIColor = .black
    private let imagesLandscape = [UIImage(named: "introSlideLand1"), UIImage(named: "introSlideLand2"), UIImage(named: "introSlideLand3")]
    private let imagesPortrait = [UIImage(named: "introSlide1"), UIImage(named: "introSlide2"), UIImage(named: "introSlide3")]
    private let imagesEightPortrait = [UIImage(named: "introSlideEight1"), UIImage(named: "introSlideEight2"), UIImage(named: "introSlideEight3")]

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let isEightPlusDevice = UIScreen.main.bounds.height == 736
        images = UIDevice.current.orientation.isLandscape ? imagesLandscape : (isEightPlusDevice ? imagesEightPortrait : imagesPortrait)

        let isTooLight = NCBrandColor.shared.customer.isTooLight()
        let isTooDark = NCBrandColor.shared.customer.isTooDark()

        if isTooLight {
            textColor = .black
            textColorOpponent = .white
        } else if isTooDark {
            textColor = .white
            textColorOpponent = .black
        } else {
            textColor = .white
            textColorOpponent = .black
        }

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.shadowColor = .clear
        navBarAppearance.shadowImage = UIImage()
        self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        self.navigationController?.view.backgroundColor = NCBrandColor.shared.customer
        self.navigationController?.navigationBar.tintColor = textColor

        if !NCManageDatabase.shared.getAllTableAccount().isEmpty {
            let navigationItemCancel = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(actionCancel(_:)))
            navigationItemCancel.tintColor = textColor
            navigationItem.leftBarButtonItem = navigationItemCancel
        }

        pageControl.currentPageIndicatorTintColor = textColor
        pageControl.pageIndicatorTintColor = .lightGray

        buttonLogin.layer.cornerRadius = 8
        buttonLogin.setTitleColor(NCBrandColor.shared.customer, for: .normal)
        buttonLogin.backgroundColor = textColor
        buttonLogin.setTitle(NSLocalizedString("_log_in_", comment: ""), for: .normal)

        buttonSignUp.layer.cornerRadius = 8
        buttonSignUp.setTitleColor(textColor, for: .normal)
        buttonSignUp.backgroundColor = textColor.withAlphaComponent(0.2)
        buttonSignUp.titleLabel?.adjustsFontSizeToFitWidth = true
        buttonSignUp.setTitle(NSLocalizedString("_sign_up_", comment: ""), for: .normal)

        buttonHost.layer.cornerRadius = 20
        buttonHost.setTitle(NSLocalizedString("_host_your_own_server", comment: ""), for: .normal)
        buttonHost.setTitleColor(textColor.withAlphaComponent(0.5), for: .normal)

        introCollectionView.register(UINib(nibName: "NCIntroCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "introCell")
        introCollectionView.dataSource = self
        introCollectionView.delegate = self
        introCollectionView.backgroundColor = NCBrandColor.shared.customer
        pageControl.numberOfPages = self.titles.count

        view.backgroundColor = NCBrandColor.shared.customer

        self.timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: (#selector(self.autoScroll(_:))), userInfo: nil, repeats: true)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if traitCollection.userInterfaceStyle == .light {
            return .lightContent
        } else {
            return .darkContent
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UIDevice.current.userInterfaceIdiom != .pad{
            AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        if UIScreen.main.bounds.width < 350 || UIScreen.main.bounds.height > 800 {
            contstraintBottomLoginButton.constant = 15
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        timer?.invalidate()
        timer = nil
        AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            let isEightPlusDevice = UIScreen.main.bounds.height == 736
            self.images = UIDevice.current.orientation.isLandscape ?  self.imagesLandscape : (isEightPlusDevice ? self.imagesEightPortrait : self.imagesPortrait)
            self.pageControl?.currentPage = 0
            self.introCollectionView?.collectionViewLayout.invalidateLayout()
        }
    }

    @objc func autoScroll(_ sender: Any?) {
        if pageControl.currentPage + 1 >= titles.count {
            pageControl.currentPage = 0
        } else {
            pageControl.currentPage += 1
        }
        introCollectionView.scrollToItem(at: IndexPath(row: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        return CGPoint.zero
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = (collectionView.dequeueReusableCell(withReuseIdentifier: "introCell", for: indexPath) as? NCIntroCollectionViewCell)!
        cell.backgroundColor = NCBrandColor.shared.customer
        cell.indexPath = indexPath
        cell.titleLabel.textColor = textColor
        cell.titleLabel.text = titles[indexPath.row]
        cell.imageView.image = images[indexPath.row]
        cell.imageView.contentMode = .scaleAspectFill
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        timer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: (#selector(autoScroll(_:))), userInfo: nil, repeats: true)
        pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Action

    @objc func actionCancel(_ sender: Any?) {
        dismiss(animated: true) { }
    }

    @IBAction func login(_ sender: Any) {
//        if let viewController = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin {
//            viewController.controller = self.controller
//            self.navigationController?.pushViewController(viewController, animated: true)
//        }
        if NCBrandOptions.shared.use_AppConfig {
            if let viewController = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLogin") as? NCLogin {
                viewController.controller = self.controller
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        } else {
            if NextcloudKit.shared.isNetworkReachable() {
                appDelegate.openLogin(viewController: navigationController, selector: NCGlobal.shared.introLogin, openLoginWeb: false)
            } else {
                showNoInternetAlert()
            }
        }
    }

    @IBAction func signupWithProvider(_ sender: Any) {
        if let viewController = UIStoryboard(name: "NCLogin", bundle: nil).instantiateViewController(withIdentifier: "NCLoginProvider") as? NCLoginProvider {
            viewController.controller = self.controller
            viewController.initialURLString = NCBrandOptions.shared.linkloginPreferredProviders
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    @IBAction func host(_ sender: Any) {
        guard let url = URL(string: NCBrandOptions.shared.linkLoginHost) else { return }
        UIApplication.shared.open(url)
    }

    func showNoInternetAlert() {
        let alertController = UIAlertController(title: NSLocalizedString("_no_internet_alert_title_", comment: ""), message: NSLocalizedString("_no_internet_alert_message_", comment: ""), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("_ok_", comment: ""), style: .default, handler: { action in }))
        self.present(alertController, animated: true)
    }
}

extension UINavigationController {
    open override var childForStatusBarStyle: UIViewController? {
        return topViewController?.childForStatusBarStyle ?? topViewController
    }
}
