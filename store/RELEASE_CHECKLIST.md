# Play Store release checklist

Most of what's left needs your Play Console and AdMob accounts, so it is
the part I cannot do for you. Items are ordered so the blocking ones come
first.

---

## 1. Blocking — the app will not work in production without these

### AdMob real ad unit ids
The app currently ships **Google's public test units**. They show a "Test
Ad" label and earn nothing.

1. Create the app in the AdMob console (https://apps.admob.com)
2. Create a **banner** unit and an **interstitial** unit
3. Put the two unit ids into `lib/core/ads/ad_config.dart`
   (`_prodBanner`, `_prodInterstitial`)
4. Put the AdMob **app id** into `android/app/src/main/AndroidManifest.xml`,
   replacing `ca-app-pub-3940256099942544~3347511713`

⚠️ The manifest app id is not optional — a production build with a wrong or
missing AdMob app id **crashes on launch**.

`AdConfig.usingTestUnits` returns true until step 3 is done, so test units
keep being used until you fill in the real ones. That is deliberate: real
units firing during development get an AdMob account suspended for invalid
traffic.

### In-app purchase product
The code expects a product id of exactly `allways_remove_ads`
(`lib/core/iap/entitlements.dart`).
1. Play Console → Monetise → In-app products → create it with that exact id
2. Set a price and **activate** it — an inactive product returns nothing
   and the purchase button will silently fail

---

## 2. Play Console paperwork

- **Data Safety form.** Declare what AdMob collects: advertising ID,
  device/diagnostic info, approximate location, and purchase history via
  Play Billing. The [privacy policy](https://avirusai1.github.io/allways-games-legal/)
  describes all of it — the form must match the policy or the submission
  is rejected.
- **Content rating questionnaire (IARC).** A word/puzzle game with ads
  should rate low, but the questionnaire is mandatory.
- **Target audience.** Declare a general audience, not children — the app
  shows ads and is not designed for under-13s.
- **Ads declaration.** Tick "contains ads". Omitting it is a policy strike.

## 3. Store listing assets — ✅ all done

- App icon 512×512 — `store/play_store_icon.png`
- Feature graphic 1024×500 — `store/screenshots/feature_graphic.png`
- Phone screenshots (8) — `store/screenshots/`, taken on a real device
- Short description and full description — `store/listing.md`

## 4. Testing track

Google requires new personal developer accounts to run a **closed test
with 12+ testers for 14 continuous days** before production access. Verify
the current rule when you get there — Google changes it.

Start this early. It is a wall-clock wait, not a work item, and it is the
single most common reason a finished app sits unreleased for a fortnight.

## 5. Build for upload

Play wants an **App Bundle**, not an APK:

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Already done in the code

- ✅ Original app icon at every density, plus the 512px store icon
- ✅ Branded splash screen (no more Flutter default)
- ✅ AdMob integrated, banner live, test/production id split
- ✅ In-app purchase flow with restore (Play requires restore to exist)
- ✅ Settings screen exposing purchase and restore
- ✅ ProGuard rules — without these the release build crashes on launch,
  because R8 strips the WorkManager database AdMob reflects into
- ✅ Package id locked to `com.techallways.games`
- ✅ Minimal permissions: internet only
- ✅ Real release signing key wired and verified (not debug)
- ✅ Store listing text, screenshots, feature graphic, and icon
- ✅ Privacy policy hosted and live: https://avirusai1.github.io/allways-games-legal/
