"""Tambahkan izin INTERNET, query intent https, dan matikan Impeller di AndroidManifest.xml (lihat README bagian 3)."""
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()

permission = '    <uses-permission android:name="android.permission.INTERNET"/>\n'
if "android.permission.INTERNET" not in text:
    start = text.index("<manifest")
    end = text.index(">", start) + 1
    text = text[:end] + "\n" + permission + text[end:]

intent = (
    "        <intent>\n"
    '            <action android:name="android.intent.action.VIEW" />\n'
    '            <data android:scheme="https" />\n'
    "        </intent>\n"
)
if 'android:scheme="https"' not in text:
    if "<queries>" in text:
        text = text.replace("<queries>\n", "<queries>\n" + intent, 1)
    else:
        text = text.replace("</manifest>", "    <queries>\n" + intent + "    </queries>\n</manifest>", 1)

# Matikan Impeller: di sebagian HP Android (GPU lama) Impeller membuat layar hitam.
impeller = (
    '        <meta-data\n'
    '            android:name="io.flutter.embedding.android.EnableImpeller"\n'
    '            android:value="false" />\n'
)
if "EnableImpeller" not in text:
    text = text.replace("</application>", impeller + "    </application>", 1)

open(path, "w", encoding="utf-8").write(text)
