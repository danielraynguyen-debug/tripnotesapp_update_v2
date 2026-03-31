#!/usr/bin/env python3
"""
Script to build Flutter APK and upload to Google Drive
Usage: python tools/drive_upload.py --version 1.0.0
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

# Google Drive API imports
try:
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    from google.oauth2 import service_account
except ImportError:
    print("❌ Missing Google API libraries. Install with:")
    print("   pip install google-api-python-client google-auth-httplib2 google-auth-oauthlib")
    sys.exit(1)


def build_apk():
    """Build release APK using Flutter"""
    print("🔨 Building Flutter APK...")
    
    result = subprocess.run(
        ["flutter", "build", "apk", "--release"],
        cwd=Path(__file__).parent.parent,
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"❌ Build failed:\n{result.stderr}")
        return None
    
    apk_path = Path(__file__).parent.parent / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    
    if not apk_path.exists():
        print("❌ APK not found after build")
        return None
    
    print(f"✅ Build successful: {apk_path}")
    return apk_path


def upload_to_drive(file_path, file_name, credentials_path):
    """Upload file to Google Drive and make it public"""
    
    # Load credentials
    credentials = service_account.Credentials.from_service_account_file(
        credentials_path,
        scopes=['https://www.googleapis.com/auth/drive']
    )
    
    service = build('drive', 'v3', credentials=credentials)
    
    # Upload file
    print(f"📤 Uploading {file_name} to Google Drive...")
    
    file_metadata = {
        'name': file_name,
        'mimeType': 'application/vnd.android.package-archive'
    }
    
    media = MediaFileUpload(
        str(file_path),
        mimetype='application/vnd.android.package-archive',
        resumable=True
    )
    
    file = service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id, webViewLink, webContentLink'
    ).execute()
    
    file_id = file.get('id')
    
    # Make file public
    print("🔓 Making file public...")
    service.permissions().create(
        fileId=file_id,
        body={'type': 'anyone', 'role': 'reader'}
    ).execute()
    
    # Get direct download link
    direct_link = f"https://drive.google.com/uc?export=download&id={file_id}"
    
    print(f"✅ Upload complete!")
    print(f"   File ID: {file_id}")
    print(f"   Direct Link: {direct_link}")
    
    return {
        'file_id': file_id,
        'direct_link': direct_link,
        'view_link': file.get('webViewLink')
    }


def create_version_json(version, apk_url, release_notes=""):
    """Create version.json file"""
    version_data = {
        "version": version,
        "apk_url": apk_url,
        "release_notes": release_notes,
        "force_update": False,
        "min_android_version": 21
    }
    
    version_file = Path(__file__).parent / "version.json"
    
    with open(version_file, 'w') as f:
        json.dump(version_data, f, indent=2)
    
    print(f"✅ Created version.json: {version_file}")
    return version_file


def main():
    parser = argparse.Argument(description='Build and upload APK to Google Drive')
    parser.add_argument('--version', required=True, help='Version number (e.g., 1.0.0)')
    parser.add_argument('--credentials', default='credentials.json', 
                        help='Path to Google service account credentials JSON')
    parser.add_argument('--notes', default='', help='Release notes')
    parser.add_argument('--skip-build', action='store_true', 
                        help='Skip build, use existing APK')
    
    args = parser.parse_args()
    
    # Check credentials
    creds_path = Path(args.credentials)
    if not creds_path.exists():
        print(f"❌ Credentials file not found: {creds_path}")
        print("   Create a Google Service Account and download the JSON key.")
        sys.exit(1)
    
    # Build APK
    if not args.skip_build:
        apk_path = build_apk()
        if not apk_path:
            sys.exit(1)
    else:
        apk_path = Path(__file__).parent.parent / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
        if not apk_path.exists():
            print(f"❌ APK not found: {apk_path}")
            sys.exit(1)
    
    # Upload APK
    upload_result = upload_to_drive(
        apk_path,
        f"app-release-{args.version}.apk",
        creds_path
    )
    
    # Create and upload version.json
    version_file = create_version_json(
        args.version,
        upload_result['direct_link'],
        args.notes
    )
    
    version_upload = upload_to_drive(
        version_file,
        "version.json",
        creds_path
    )
    
    print("\n" + "="*60)
    print("🎉 Upload complete!")
    print("="*60)
    print(f"APK URL: {upload_result['direct_link']}")
    print(f"Version JSON URL: {version_upload['direct_link']}")
    print("\n⚠️  Update DriveUpdateService.versionJsonUrl with:")
    print(f"   {version_upload['direct_link']}")
    print("="*60)


if __name__ == "__main__":
    main()
