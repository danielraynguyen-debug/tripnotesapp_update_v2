"""Google Drive authentication utilities"""
import os
import pickle
import sys
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
