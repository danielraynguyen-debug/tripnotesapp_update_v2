import os
import json
import pickle
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

CLIENT_SECRETS_FILE = os.path.join(os.path.dirname(__file__), '..', 'client_secret.json')
TOKEN_PICKLE_FILE = os.path.join(os.path.dirname(__file__), '..', 'token.pickle')
SCOPES = ['https://www.googleapis.com/auth/drive']
FOLDER_ID = '1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB'

def get_drive_service():
    creds = None
    if os.path.exists(TOKEN_PICKLE_FILE):
        with open(TOKEN_PICKLE_FILE, 'rb') as token:
            creds = pickle.load(token)
    
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
            creds = flow.run_local_server(port=0)
        with open(TOKEN_PICKLE_FILE, 'wb') as token:
            pickle.dump(creds, token)
    
    return build('drive', 'v3', credentials=creds)

def main():
    # Tạo version.json với version CAO HƠN app hiện tại (0.8.0)
    version_data = {
        "latest_version": "1.0.0",  # Cao hơn 0.8.0 để trigger force update
        "update_url": "https://drive.google.com/uc?export=download&id=1QZEAMVlZjrfPaBFckNS7Zju7TGp9PTx1",
        "force_update": True,
        "release_notes": "Cập nhật bảo mật quan trọng!"
    }
    
    version_path = os.path.join(os.path.dirname(__file__), 'version.json')
    with open(version_path, 'w', encoding='utf-8') as f:
        json.dump(version_data, f, indent=2, ensure_ascii=False)
    
    print(f"📝 Đã tạo version.json với version: {version_data['latest_version']}")
    print(f"📱 App hiện tại: 0.8.0 → Sẽ thấy có cập nhật bắt buộc!")
    
    # Upload lên Google Drive
    service = get_drive_service()
    
    # Tìm file cũ
    results = service.files().list(
        q=f"name='version.json' and '{FOLDER_ID}' in parents",
        spaces='drive',
        fields='files(id, name)'
    ).execute()
    
    media = MediaFileUpload(version_path, mimetype='application/json', resumable=True)
    
    if results['files']:
        file_id = results['files'][0]['id']
        service.files().update(fileId=file_id, media_body=media).execute()
        print(f"✅ Đã cập nhật version.json (ID: {file_id})")
    else:
        file_metadata = {'name': 'version.json', 'parents': [FOLDER_ID]}
        file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        print(f"✅ Đã upload version.json mới (ID: {file.get('id')})")
    
    print("\n🧪 Để test:")
    print("1. Cài APK hiện tại (0.8.0) lên điện thoại")
    print("2. Mở app → Sẽ hiện dialog 'Cập nhật bắt buộc'")
    print("3. Không thể tắt dialog, bắt buộc phải cập nhật")

if __name__ == '__main__':
    main()
