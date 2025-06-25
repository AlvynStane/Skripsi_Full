# **Getting Started**
### How to run Flutter App:
1. Clone the repository:  
   `git clone https://github.com/michaellay19/SKRIPSI.git`  
   `cd Skripsi_Full/Flutter`
   
2. Install dependencies:  
   `flutter pub get`
   
3. Run the app:  
   `flutter run`

### How to run Firebase Cloud Function:
1. Clone the repository:  
   `git clone https://github.com/michaellay19/SKRIPSI.git`  
   `cd Skripsi_Full/Firebase\ Cloud\ Function`
   
2. Add service account key:
- Download the file mentioned in `Link serviceAccountKey.txt`
- Rename it to `serviceAccountKey.json`
- Place it in the `Firebase Cloud Function` directory

3. Install dependencies:  
   `npm install`
  
4. Set up Firebase (if not already):  
  `firebase login`  
  `firebase use --add`

5. Run locally (optional):  
  `firebase emulators:start`

6. Deploy to Firebase:  
  `firebase deploy --only functions`
