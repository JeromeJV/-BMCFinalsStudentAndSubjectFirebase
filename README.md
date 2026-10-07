# Biodata Form

Flutter Web app na gumagamit ng Firebase Authentication at Cloud Firestore.

## Lokal na pagtakbo

```powershell
flutter pub get
flutter run -d chrome
```

## Firebase Hosting

Kailangan ang Flutter SDK, Node.js/npm, at Firebase CLI (`npm install -g firebase-tools`).

```powershell
firebase login
flutter build web --release
firebase deploy --only hosting --project valdepena-harvey-jerome-17
```

Ang Firebase project ID ay nakatakda sa `.firebaserc`; ang Hosting ay naghahain ng
`build/web` at nire-rewrite ang app routes sa `index.html`.

## Awtomatikong deploy mula sa GitHub

Ang workflow na `.github/workflows/firebase-hosting.yml` ay nagbu-build at
nagde-deploy ng live site sa bawat push sa `main`. Para paganahin ito:

1. Gumawa ng GitHub repository at i-push rito ang project branch na `main`.
2. Sa Firebase Console, gumawa ng service-account key na may pahintulot mag-deploy
   sa Firebase Hosting.
3. Sa GitHub repository, buksan ang **Settings → Secrets and variables → Actions**
   at magdagdag ng repository secret na `FIREBASE_SERVICE_ACCOUNT_VALDEPENA_HARVEY_JEROME_17`.
   Ilagay ang buong JSON ng service-account key bilang value; huwag itong i-commit
   o ibahagi sa chat.
4. Pagkatapos ng push sa `main`, tingnan ang **Actions** tab para sa resulta at
   hanapin ang live URL sa Firebase Console → Hosting.

Huwag i-commit ang private service-account key. Naka-ignore sa Git ang mga
service-account JSON file at local build outputs.
