import Foundation

// MARK: - AdConfig
// All AdMob IDs in one place.
//
// ============================================================================
// !! BEFORE PUBLISHING TO THE APP STORE:
//    Replace the TEST IDs below with your REAL AdMob IDs from https://admob.google.com
//    Also update the `GADApplicationIdentifier` key in Info.plist!
// ============================================================================

public enum AdConfig {
    // MARK: - App ID
    /// TODO: Replace with your REAL AdMob App ID before release.
    /// Real format: "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
    /// Also make sure this matches GADApplicationIdentifier in Info.plist!
    public static let admobAppID = "ca-app-pub-3940256099942544~1458002511"

    // MARK: - Banner Ad Unit ID
    /// TODO: Replace with your REAL Banner Ad Unit ID before release.
    /// Real format: "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    public static let bannerDrawScreen = "ca-app-pub-3940256099942544/2934735716"
}
