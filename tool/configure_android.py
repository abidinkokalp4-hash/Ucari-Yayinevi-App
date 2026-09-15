from pathlib import Path
p = Path('android/app/src/main/AndroidManifest.xml')
s = p.read_text().replace('android:label="ucari_yayinevi"', 'android:label="UÇARI Yayınevi"')
s = s.replace('<application', '<uses-permission android:name="android.permission.INTERNET"/>\n    <application', 1)
s = s.replace('<application', '<application android:allowBackup="false"', 1)
p.write_text(s)
p = Path('android/app/build.gradle.kts')
s = p.read_text().replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
p.write_text(s)
