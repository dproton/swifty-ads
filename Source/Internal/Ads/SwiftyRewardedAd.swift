//
//  SwiftyRewardedAd.swift
//  SwiftyAd
//
//  Created by Dominik Ringler on 21/02/2020.
//  Copyright © 2020 Dominik. All rights reserved.
//

import GoogleMobileAds

protocol SwiftyRewardedAdType: AnyObject {
    var isReady: Bool { get }
    func load()
    func show(from viewController: UIViewController)
}

final class SwiftyRewardedAd: NSObject {
    
    // MARK: - Properties
    
    private let adUnitId: String
    private let request: () -> GADRequest
    private let didOpen: () -> Void
    private let didClose: () -> Void
    private let didReward: (Int) -> Void
    
    private var rewardedAd: GADRewardedAd? // new API
    
    // MARK: - Init
    
    init(adUnitId: String,
         request: @escaping () -> GADRequest,
         didOpen: @escaping () -> Void,
         didClose: @escaping () -> Void,
         didReward: @escaping (Int) -> Void) {
        self.adUnitId = adUnitId
        self.request = request
        self.didOpen = didOpen
        self.didClose = didClose
        self.didReward = didReward
    }
}

// MARK: - SwiftyRewardedAdType

extension SwiftyRewardedAd: SwiftyRewardedAdType {
    
    var isReady: Bool {
        guard rewardedAd?.isReady == true else {
            print("AdMob reward video is not ready, reloading...")
            load()
            return false
        }
        return true
    }
    
    func load() {
        rewardedAd = GADRewardedAd(adUnitID: adUnitId)
        rewardedAd?.load(request()) { error in
          if let error = error {
            print("Loading failed: \(error)")
          } else {
            print("Loading Succeeded")
          }
        }
    }
 
    func show(from viewController: UIViewController) {
        if isReady {
            rewardedAd?.present(fromRootViewController: viewController, delegate: self)
        } else {
            let alertController = UIAlertController(
                title: LocalizedString.sorry,
                message: LocalizedString.noVideo,
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: LocalizedString.ok, style: .cancel))
            viewController.present(alertController, animated: true)
        }
    }
}

// MARK: - GADRewardedAdDelegate

extension SwiftyRewardedAd: GADRewardedAdDelegate {
    
    func rewardedAdDidPresent(_ rewardedAd: GADRewardedAd) {
        print("AdMob reward based video did present ad from: \(rewardedAd.responseInfo?.adNetworkClassName ?? "")")
        didOpen()
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        didClose()
        load()
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        print(error.localizedDescription)
        // Do not reload here as it might cause endless loading loops if no/slow internet
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        print("AdMob reward based video ad did reward user with \(reward)")
        let rewardAmount = Int(truncating: reward.amount)
        didReward(rewardAmount)
    }
}
