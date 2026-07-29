path = "android/app/src/main/AndroidManifest.xml"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

permissions = (
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n'
    '    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>\n'
    '    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>\n'
    '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>\n'
    '    <application'
)
content = content.replace("<application", permissions, 1)

receivers = (
    '<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />\n'
    '        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">\n'
    '            <intent-filter>\n'
    '                <action android:name="android.intent.action.BOOT_COMPLETED"/>\n'
    '                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>\n'
    '                <action android:name="android.intent.action.QUICKBOOT_POWERON" />\n'
    '                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>\n'
    '            </intent-filter>\n'
    '        </receiver>\n'
    '    </application>'
)
content = content.replace("</application>", receivers, 1)

with open(path, "w", encoding="utf-8") as f:
    f.write(content)

print("AndroidManifest.xml bildirim izinleriyle guncellendi.")
