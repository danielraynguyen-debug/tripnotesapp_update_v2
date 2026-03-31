from google_auth import get_drive_service, FOLDER_ID
from googleapiclient.http import MediaFileUpload
import json
import os

def upload_version_json_only():
    """Upload version.json thủ công với version cao hơn app"""
    service = get_drive_service()
    
    # Tạo version.json với version cao hơn app hiện tại (0.8.0)
    version_data = {
        "latest_version": "1.0.0",  # Cao hơn 0.8.0
        "update_url": "https://drive.google.com/uc?export=download&id=1QZEAMVlZjrfPaBFckNS7Zju7TGp9PTx1",
        "force_update": True,
        "release_notes": "Cập nhật bảo mật quan trọng!"
    }
    
    version_path = os.path.join(os.path.dirname(__file__), 'version.json')
    with open(version_path, 'w', encoding='utf-8') as f:
        json.dump(version_data, f, indent=2, ensure_ascii=False)
    
    # Tìm file version.json cũ trên Drive
    results = service.files().list(
        q=f"name='version.json' and '{FOLDER_ID}' in parents",
        spaces='drive',
        fields='files(id, name)'
    ).execute()
    
    media_body = MediaFileUpload(version_path, mimetype='application/json', resumable=True)
    
    if results['files']:
        # Update file cũ
        file_id = results['files'][0]['id']
        service.files().update(
            fileId=file_id,
            media_body=media_body
        ).execute()
        print(f"✅ Đã cập nhật version.json (ID: {file_id})")
    else:
        # Upload file mới
        file_metadata = {
            'name': 'version.json',
            'parents': [FOLDER_ID]
        }
        file = service.files().create(
            body=file_metadata,
            media_body=media_body,
            fields='id'
        ).execute()
        print(f"✅ Đã upload version.json mới (ID: {file['id']})")
    
    print(f"📊 Version trong file: {version_data['latest_version']}")
    print("🧪 App hiện tại (0.8.0) sẽ thấy có cập nhật bắt buộc!")

if __name__ == '__main__':
    upload_version_json_only()
