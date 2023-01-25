//
//  NCIntroViewController.swift
//  Nextcloud
//
//  Created by Philippe Weidmann on 24.12.19.
//  Copyright © 2019 Philippe Weidmann. All rights reserved.
//  Copyright © 2019 Marino Faggiana All rights reserved.
//
//  Author Philippe Weidmann
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
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
import NextcloudKit

class NCIntroViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var buttonLogin: UIButton!
    @IBOutlet weak var buttonSignUp: UIButton!
    @IBOutlet weak var buttonHost: UIButton!
    @IBOutlet weak var introCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var contstraintBottomLoginButton: NSLayoutConstraint!
    
    @objc var delegate: NCIntroViewController?
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let titles = [NSLocalizedString("", comment: ""), NSLocalizedString("", comment: ""), NSLocalizedString("", comment: "")]
    private var images:[UIImage?] = []
    private var timerAutoScroll: Timer?
    private var textColor: UIColor = .white
    private var textColorOpponent: UIColor = .black
    private let imagesLandscape = [UIImage(named: "introSlideLand1"), UIImage(named: "introSlideLand2"), UIImage(named: "introSlideLand3")]
    private let imagesPortrait = [UIImage(named: "introSlide1"), UIImage(named: "introSlide2"), UIImage(named: "introSlide3")]
    private let imagesEightPortrait = [UIImage(named: "introSlideEight1"), UIImage(named: "introSlideEight2"), UIImage(named: "introSlideEight3")]
    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        let isEightPlusDevice = UIScreen.main.bounds.height == 736
        images = UIDevice.current.orientation.isLandscape ?  imagesLandscape : (isEightPlusDevice ? imagesEightPortrait : imagesPortrait)
        
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
        
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.shadowColor = .clear
            navBarAppearance.shadowImage = UIImage()
            self.navigationController?.navigationBar.standardAppearance = navBarAppearance
        } else {
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.backgroundColor = .clear
            self.navigationController?.navigationBar.barTintColor = NCBrandColor.shared.customer
        }
        self.navigationController?.navigationBar.tintColor = textColor

        
        self.pageControl.currentPageIndicatorTintColor = textColor
        self.pageControl.pageIndicatorTintColor = .lightGray

        self.buttonLogin.layer.cornerRadius = 4
        self.buttonLogin.setTitleColor(NCBrandColor.shared.brand, for: .normal)
        self.buttonLogin.backgroundColor = textColor
        self.buttonLogin.setTitle(NSLocalizedString("_log_in_", comment: ""), for: .normal)

        self.buttonSignUp.layer.cornerRadius = 20
        self.buttonSignUp.setTitleColor(.white, for: .normal)
        self.buttonSignUp.backgroundColor = UIColor(red: 25.0 / 255.0, green: 89.0 / 255.0, blue: 141.0 / 255.0, alpha: 1)
        self.buttonSignUp.setTitle(NSLocalizedString("_sign_up_", comment: ""), for: .normal)

        self.buttonHost.layer.cornerRadius = 20
        self.buttonHost.setTitle(NSLocalizedString("_host_your_own_server", comment: ""), for: .normal)
        self.buttonHost.setTitleColor(textColor.withAlphaComponent(0.5), for: .normal)

        self.introCollectionView.register(UINib(nibName: "NCIntroCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "introCell")
        self.introCollectionView.dataSource = self
        self.introCollectionView.delegate = self
        self.introCollectionView.backgroundColor = NCBrandColor.shared.customer
        self.pageControl.numberOfPages = self.titles.count
        self.view.backgroundColor = NCBrandColor.shared.customer
        self.timerAutoScroll = Timer.scheduledTimer(timeInterval: 5, target: self, selector: (#selector(NCIntroViewController.autoScroll)), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(resetPageController(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (UIDevice.current.userInterfaceIdiom != .pad){
            AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
        }
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidLayoutSubviews() {
        if UIScreen.main.bounds.width < 350 || UIScreen.main.bounds.height > 800 {
            contstraintBottomLoginButton.constant = 15
        }
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                return .lightContent
            } else {
                return .darkContent
            }
        } else {
            return .lightContent
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timerAutoScroll?.invalidate()
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.all)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        let isEightPlusDevice = UIScreen.main.bounds.height == 736
        images = UIDevice.current.orientation.isLandscape ?  imagesLandscape : (isEightPlusDevice ? imagesEightPortrait : imagesPortrait)
        pageControl.currentPage = 0
        introCollectionView.collectionViewLayout.invalidateLayout()
        self.introCollectionView.reloadData()
    }
    
    @objc func resetPageController(_ notification: NSNotification){
        pageControl.currentPage = 0
        introCollectionView.scrollToItem(at: IndexPath(row: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: true)
    }

    @objc func autoScroll() {
        if(pageControl.currentPage + 1 >= titles.count) {
            pageControl.currentPage = 0
        }
        else {
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "introCell", for: indexPath) as! NCIntroCollectionViewCell
        cell.backgroundColor = NCBrandColor.shared.customer

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
        timerAutoScroll = Timer.scheduledTimer(timeInterval: 5, target: self, selector: (#selector(NCIntroViewController.autoScroll)), userInfo: nil, repeats: true)
        let page = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        if pageControl.currentPage == (images.count - 1), pageControl.currentPage <= page {
            pageControl.currentPage = 0
            introCollectionView.scrollToItem(at: IndexPath(row: pageControl.currentPage, section: 0), at: .centeredHorizontally, animated: false)
        } else {
            pageControl.currentPage = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        timerAutoScroll?.invalidate()
    }

    @IBAction func login(_ sender: Any) {
        if NextcloudKit.shared.isNetworkReachable() {
            appDelegate.openLogin(viewController: navigationController, selector: NCGlobal.shared.introLogin, openLoginWeb: false)
        } else {
            showNoInternetAlert()
        }
        
    }

    @IBAction func signup(_ sender: Any) {
        appDelegate.openLogin(viewController: navigationController, selector: NCGlobal.shared.introSignup, openLoginWeb: false)
    }

    @IBAction func host(_ sender: Any) {
        guard let url = URL(string: NCBrandOptions.shared.linkLoginHost) else { return }
        UIApplication.shared.open(url)
    }
    
    func showNoInternetAlert(){
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
