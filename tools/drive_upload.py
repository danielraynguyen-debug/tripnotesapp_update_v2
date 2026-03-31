import os
from google.oauth2 import service_account
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

def upload_file(service, file_path, file_name, mime_type, folder_id=None):
    # Tìm file trùng tên trong thư mục (nếu có thì ghi đè)
    query = f"name='{file_name}'"
    if folder_id:
        query += f" and '{folder_id}' in parents"
    results = service.files().list(q=query, spaces='drive', fields='files(id, name)').execute()
    files = results.get('files', [])
    if files:
        file_id = files[0]['id']
        media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True)
        updated = service.files().update(fileId=file_id, media_body=media).execute()
        print(f"Updated {file_name}, file ID: {updated.get('id')}")
        return updated.get('id')
    else:
        file_metadata = {'name': file_name}
        if folder_id:
            file_metadata['parents'] = [folder_id]
        media = MediaFileUpload(file_path, mimetype=mime_type, resumable=True)
        file = service.files().create(body=file_metadata, media_body=media, fields='id').execute()
        print(f"Uploaded {file_name}, file ID: {file.get('id')}")
        return file.get('id')

def main():
    SERVICE_ACCOUNT_FILE = os.path.join(os.path.dirname(__file__), '..', 'credentials.json')
    SCOPES = ['https://www.googleapis.com/auth/drive']
    FOLDER_ID = '1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB'  # Thay bằng ID thư mục Drive muốn upload vào hoặc để None nếu upload lên My Drive

    creds = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    service = build('drive', 'v3', credentials=creds)

    # Upload version.json
    upload_file(service, 'version.json', 'version.json', 'application/json', FOLDER_ID)
    # Upload APK
    upload_file(service, 'app-release.apk', 'app-release.apk', 'application/vnd.android.package-archive', FOLDER_ID)

if __name__ == '__main__':
    main()
