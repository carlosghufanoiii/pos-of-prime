# 🔑 Get Firebase Admin SDK Service Account Key

## Step-by-Step Instructions

1. **Open Firebase Console**:
   - Go to: https://console.firebase.google.com/
   - Select your project: **prime-pos-system**

2. **Navigate to Service Accounts**:
   - Click the ⚙️ **Settings** icon (top left)
   - Select **Project settings**
   - Click on **Service accounts** tab

3. **Generate Private Key**:
   - You should see: "Firebase Admin SDK"
   - Click **Generate new private key** button
   - A popup will ask "Generate new private key?"
   - Click **Generate key**

4. **Download the JSON File**:
   - A JSON file will be downloaded automatically
   - It will be named something like: `prime-pos-system-firebase-adminsdk-xxxxx.json`
   - This file contains your private key and credentials

5. **Move the File**:
   - Move the downloaded file to: `/home/zyph/Downloads/`
   - Or note the exact path where it was saved

6. **Run Setup Script**:
   ```bash
   cd /home/zyph/Documents/prime-pos/backend
   node setup-firebase-admin.js /home/zyph/Downloads/prime-pos-system-firebase-adminsdk-xxxxx.json
   ```

## ⚠️ Important Notes

- **Keep this file secure** - it contains admin credentials
- **Never commit it to git** - add to .gitignore
- **Don't share it** - anyone with this file has admin access to your Firebase

## What the File Looks Like

The service account JSON should look like this:
```json
{
  "type": "service_account",
  "project_id": "prime-pos-system",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@prime-pos-system.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

Once you have this file, I can complete the production setup!