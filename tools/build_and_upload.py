import os
import json
import sys
import pickle
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

# Cấu hình
CLIENT_SECRETS_FILE = os.path.join(os.path.dirname(__file__), '..', 'client_secret.json')
TOKEN_PICKLE_FILE = os.path.join(os.path.dirname(__file__), '..', 'token.pickle')
SCOPES = ['https://www.googleapis.com/auth/drive']
FOLDER_ID = '1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB'

def get_drive_service():
    """Khởi tạo Google Drive service với OAuth 2.0"""
    creds = None
    
    # Load token từ file nếu đã tồn tại
    if os.path.exists(TOKEN_PICKLE_FILE):
        with open(TOKEN_PICKLE_FILE, 'rb') as token:
            creds = pickle.load(token)
    
    # Nếu không có credentials hợp lệ, thực hiện OAuth flow
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not os.path.exists(CLIENT_SECRETS_FILE):
                print(f"❌ Không tìm thấy {CLIENT_SECRETS_FILE}")
                print("\n📋 Hướng dẫn tạo OAuth credentials:")
                print("1. Vào https://console.cloud.google.com/")
                print("2. Tạo project hoặc chọn project đã có")
                print("3. APIs & Services → Credentials → Create Credentials → OAuth client ID")
                print("4. Application type: Desktop app")
                print("5. Name: TripNotes Upload")
                print("6. Download JSON, đổi tên thành client_secret.json, đặt vào thư mục gốc project")
                print("\n⚠️  Quan trọng: Cần bật Google Drive API trước:")
                print("   APIs & Services → Library → Search 'Google Drive API' → Enable")
                sys.exit(1)
            
            flow = InstalledAppFlow.from_client_secrets_file(CLIENT_SECRETS_FILE, SCOPES)
            print("🔐 Mở trình duyệt để xác thực Google Drive...")
            creds = flow.run_local_server(port=0)
        
        # Lưu token để dùng cho lần sau
        with open(TOKEN_PICKLE_FILE, 'wb') as token:
            pickle.dump(creds, token)
    
    return build('drive', 'v3', credentials=creds)

def upload_or_update_file(service, file_path, file_name, mime_type, folder_id=None, make_public=False):
    """Upload file mới hoặc cập nhật file đã tồn tại"""
    query = f"name='{file_name}'"
    if folder_id:
        query += f" and '{folder_id}' in parents"
    
    results = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    files = results.get('files', [])
    
    media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True)
    
    if files:
        file_id = files[0]['id']
        updated = service.files().update(fileId=file_id, media_body=media).execute()
        print(f"✅ Đã cập nhật: {file_name} (ID: {updated.get('id')})")
        return updated.get('id')
    else:
        file_metadata = {'name': file_name}
        if folder_id:
            file_metadata['parents'] = [folder_id]
        file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        file_id = file.get('id')
        print(f"✅ Đã upload mới: {file_name} (ID: {file_id})")
        
        # Công khai file để app có thể download
        if make_public:
            permission = {'type': 'anyone', 'role': 'reader'}
            service.permissions().create(fileId=file_id, body=permission).execute()
            print(f"🔗 File đã được công khai: https://drive.google.com/uc?export=download&id={file_id}")
        
        return file_id

def create_version_json(version, update_url, force_update=True):
    """Tạo file version.json"""
    version_data = {
        "latest_version": version,
        "update_url": update_url,
        "force_update": force_update,
        "release_notes": "Cập nhật mới"
    }
    
    version_path = os.path.join(os.path.dirname(__file__), 'version.json')
    with open(version_path, 'w', encoding='utf-8') as f:
        json.dump(version_data, f, indent=2, ensure_ascii=False)
    
    return version_path

def main():
    # Build APK trước khi upload
    print("🔨 Đang build APK release...")
    os.chdir(os.path.join(os.path.dirname(__file__), '..'))
    result = os.system('flutter build apk --release')
    if result != 0:
        print("❌ Build thất bại!")
        sys.exit(1)
    
    apk_path = os.path.join('build', 'app', 'outputs', 'flutter-apk', 'app-release.apk')
    if not os.path.exists(apk_path):
        print(f"❌ Không tìm thấy APK tại: {apk_path}")
        sys.exit(1)
    
    # Lấy version từ pubspec.yaml
    pubspec_path = os.path.join(os.path.dirname(__file__), '..', 'pubspec.yaml')
    version = "1.0.0"
    with open(pubspec_path, 'r') as f:
        for line in f:
            if line.strip().startswith('version:'):
                version = line.split(':')[1].strip().split('+')[0]
                break
    
    print(f"📱 Phiên bản: {version}")
    
    # Khởi tạo Drive service
    service = get_drive_service()
    
    # Upload APK trước để lấy link
    print("\n📤 Đang upload APK lên Google Drive...")
    apk_id = upload_or_update_file(service, apk_path, 'app-release.apk', 
                                    'application/vnd.android.package-archive', 
                                    FOLDER_ID, make_public=True)
    
    # Tạo link download trực tiếp
    update_url = f"https://drive.google.com/uc?export=download&id={apk_id}"
    
    # Tạo version.json
    print("\n📝 Đang tạo version.json...")
    version_path = create_version_json(version, update_url, force_update=True)
    
    # Upload version.json
    print("📤 Đang upload version.json...")
    version_id = upload_or_update_file(service, version_path, 'version.json',
                                        'application/json', FOLDER_ID, make_public=True)
    
    # In thông tin cấu hình
    print("\n" + "="*60)
    print("✅ HOÀN TẤT UPLOAD!")
    print("="*60)
    print(f"📁 File version ID: {version_id}")
    print(f"🔗 Link version.json: https://drive.google.com/uc?export=download&id={version_id}")
    print(f"\n📝 Cập nhật notification_service.dart với FILE_ID:")
    print(f"   {version_id}")
    print("="*60)

if __name__ == '__main__':
    main()
