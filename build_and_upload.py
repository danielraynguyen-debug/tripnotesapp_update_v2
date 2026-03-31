#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Flutter Build & Google Drive Auto-Upload Script
================================================

Tự động hóa quy trình build release APK và upload lên Google Drive:
1. Build Flutter APK release
2. Upload APK lên Google Drive
3. Upload version.json lên Google Drive
4. Tự động cập nhật FILE_ID vào UpdateService.dart

Cài đặt:
    pip install -r requirements.txt

Usage:
    python build_and_upload.py --version 1.1.0 --build-number 2 --force-update

Author: Assistant
"""

import os
import sys
import json
import argparse
import subprocess
import platform
from pathlib import Path
from datetime import datetime
from shutil import which

# Google Drive API imports
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from googleapiclient.errors import HttpError

# Constants
SCOPES = ['https://www.googleapis.com/auth/drive']
PROJECT_ROOT = Path(__file__).parent.absolute()
APK_PATH = PROJECT_ROOT / 'build' / 'app' / 'outputs' / 'flutter-apk' / 'app-release.apk'
VERSION_JSON_PATH = PROJECT_ROOT / 'version.json'
UPDATE_SERVICE_PATH = PROJECT_ROOT / 'lib' / 'core' / 'services' / 'update_service.dart'
CREDENTIALS_PATH = PROJECT_ROOT / 'credentials.json'
TOKEN_PATH = PROJECT_ROOT / 'token.json'

# Màu sắc cho terminal
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'


def print_colored(text: str, color: str = Colors.GREEN, bold: bool = False):
    """In text với màu trong terminal"""
    prefix = Colors.BOLD if bold else ''
    print(f"{prefix}{color}{text}{Colors.END}")


def get_google_drive_service():
    """
    Khởi tạo và trả về Google Drive API service
    
    Returns:
        build: Google Drive API service instance
    """
    creds = None
    
    # Kiểm tra token đã tồn tại
    if TOKEN_PATH.exists():
        creds = Credentials.from_authorized_user_file(str(TOKEN_PATH), SCOPES)
    
    # Nếu không có credentials hoặc đã hết hạn
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            print_colored("Refreshing access token...", Colors.YELLOW)
            creds.refresh(Request())
        else:
            if not CREDENTIALS_PATH.exists():
                print_colored(
                    "Lỗi: Không tìm thấy file credentials.json!", 
                    Colors.RED, bold=True
                )
                print_colored(
                    "Vui lòng tải file credentials từ Google Cloud Console:", 
                    Colors.YELLOW
                )
                print("  1. Truy cập https://console.cloud.google.com/")
                print("  2. Tạo project và enable Google Drive API")
                print("  3. Tạo OAuth2 credentials và tải về")
                print("  4. Đổi tên thành 'credentials.json' và đặt trong thư mục project")
                sys.exit(1)
            
            print_colored("Chạy OAuth2 flow để lấy token...", Colors.CYAN)
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_PATH), SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Lưu token cho lần sau
        with open(TOKEN_PATH, 'w') as token:
            token.write(creds.to_json())
        print_colored("Token đã được lưu!", Colors.GREEN)
    
    return build('drive', 'v3', credentials=creds)


def upload_to_drive(service, file_path: Path, file_name: str, mime_type: str = None) -> str:
    """
    Upload file lên Google Drive
    
    Args:
        service: Google Drive API service
        file_path: Đường dẫn đến file cần upload
        file_name: Tên file trên Drive
        mime_type: MIME type của file
        
    Returns:
        str: File ID của file vừa upload
    """
    try:
        file_metadata = {
            'name': file_name,
            'description': f'Auto-uploaded on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}',
        }
        
        media = MediaFileUpload(
            str(file_path),
            mimetype=mime_type,
            resumable=True
        )
        
        print_colored(f"Đang upload {file_name} lên Google Drive...", Colors.CYAN)
        
        file = service.files().create(
            body=file_metadata,
            media_body=media,
            fields='id, webViewLink'
        ).execute()
        
        file_id = file.get('id')
        web_link = file.get('webViewLink')
        
        print_colored(f"✓ Upload thành công!", Colors.GREEN, bold=True)
        print(f"  File ID: {Colors.CYAN}{file_id}{Colors.END}")
        print(f"  Link: {Colors.BLUE}{web_link}{Colors.END}")
        
        # Set file permission to public
        permission = {
            'type': 'anyone',
            'role': 'reader'
        }
        service.permissions().create(
            fileId=file_id,
            body=permission
        ).execute()
        print_colored("✓ Đã set quyền public cho file", Colors.GREEN)
        
        return file_id
        
    except HttpError as e:
        print_colored(f"Lỗi khi upload: {e}", Colors.RED, bold=True)
        raise


def update_file_on_drive(service, file_id: str, file_path: Path):
    """
    Cập nhật file đã tồn tại trên Drive
    
    Args:
        service: Google Drive API service
        file_id: ID của file cần update
        file_path: Đường dẫn đến file mới
    """
    try:
        media = MediaFileUpload(
            str(file_path),
            resumable=True
        )
        
        print_colored(f"Đang cập nhật file {file_id}...", Colors.CYAN)
        
        file = service.files().update(
            fileId=file_id,
            media_body=media,
            fields='id, webViewLink'
        ).execute()
        
        print_colored(f"✓ Cập nhật thành công!", Colors.GREEN, bold=True)
        return file.get('id')
        
    except HttpError as e:
        print_colored(f"Lỗi khi cập nhật: {e}", Colors.RED, bold=True)
        raise


def get_flutter_command():
    """
    Tìm lệnh flutter phù hợp với hệ điều hành
    Returns:
        str: 'flutter' hoặc 'flutter.bat' hoặc đường dẫn đầy đủ
    """
    system = platform.system()
    
    # Thử tìm flutter trong PATH
    flutter_cmd = which('flutter')
    if flutter_cmd:
        return flutter_cmd
    
    # Nếu không tìm thấy, thử các vị trí phổ biến trên Windows
    if system == 'Windows':
        possible_paths = [
            Path(os.environ.get('FLUTTER_ROOT', ''), 'bin', 'flutter.bat'),
            Path.home() / 'flutter' / 'bin' / 'flutter.bat',
            Path('C:/flutter/bin/flutter.bat'),
            Path('C:/src/flutter/bin/flutter.bat'),
            Path('D:/flutter/bin/flutter.bat'),
        ]
        
        # Kiểm tra từng đường dẫn
        for path in possible_paths:
            if path.exists():
                return str(path)
        
        # Nếu không tìm thấy, trả về 'flutter' và để shell xử lý
        return 'flutter'
    
    return 'flutter'


def run_flutter_command(args_list, cwd=None, capture_output=True):
    """
    Chạy lệnh flutter với xử lý đa nền tảng
    
    Args:
        args_list: List các arguments (e.g., ['clean'], ['build', 'apk'])
        cwd: Working directory
        capture_output: Có capture stdout/stderr không
        
    Returns:
        subprocess.CompletedProcess
    """
    flutter_cmd = get_flutter_command()
    cmd = [flutter_cmd] + args_list
    
    print_colored(f"Running: {' '.join(cmd)}", Colors.CYAN)
    
    try:
        # Trên Windows, sử dụng shell=True để tìm command trong PATH
        use_shell = platform.system() == 'Windows'
        
        result = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            encoding='utf-8',
            errors='replace',
            shell=use_shell
        )
        return result
        
    except FileNotFoundError as e:
        print_colored(f"Không tìm thấy Flutter SDK!", Colors.RED, bold=True)
        print_colored(f"Chi tiết: {e}", Colors.RED)
        print_colored("\nCác cách khắc phục:", Colors.YELLOW, bold=True)
        print("  1. Thêm Flutter vào PATH hệ thống")
        print("  2. Hoặc set biến môi trường FLUTTER_ROOT=C:\\flutter")
        print("  3. Hoặc sửa script và hardcode đường dẫn trong get_flutter_command()")
        raise
    except Exception as e:
        print_colored(f"Lỗi khi chạy flutter: {e}", Colors.RED, bold=True)
        raise


def build_flutter_apk():
    """
    Build Flutter APK release
    
    Returns:
        bool: True nếu build thành công, False nếu thất bại
    """
    print_colored("\n" + "="*60, Colors.CYAN, bold=True)
    print_colored("BẮT ĐẦU BUILD FLUTTER APK", Colors.CYAN, bold=True)
    print_colored("="*60, Colors.CYAN, bold=True)
    
    try:
        # Clean build trước
        print_colored("\n[1/3] Cleaning previous build...", Colors.YELLOW)
        result = run_flutter_command(['clean'], cwd=PROJECT_ROOT)
        if result.returncode != 0:
            print_colored(f"Warning: flutter clean failed: {result.stderr}", Colors.YELLOW)
        
        # Get dependencies
        print_colored("[2/3] Getting dependencies...", Colors.YELLOW)
        result = run_flutter_command(['pub', 'get'], cwd=PROJECT_ROOT)
        if result.returncode != 0:
            print_colored(f"Lỗi: flutter pub get failed!", Colors.RED, bold=True)
            print(result.stderr)
            return False
        print_colored("✓ Dependencies ready", Colors.GREEN)
        
        # Build APK
        print_colored("[3/3] Building release APK...", Colors.YELLOW)
        result = run_flutter_command(['build', 'apk', '--release'], cwd=PROJECT_ROOT)
        
        if result.returncode != 0:
            print_colored(f"Lỗi: Build thất bại!", Colors.RED, bold=True)
            print(result.stderr)
            return False
        
        print_colored("✓ Build thành công!", Colors.GREEN, bold=True)
        
        # Kiểm tra file APK tồn tại
        if not APK_PATH.exists():
            print_colored(f"Lỗi: Không tìm thấy file APK tại {APK_PATH}", Colors.RED, bold=True)
            return False
        
        # Lấy thông tin file
        file_size = APK_PATH.stat().st_size / (1024 * 1024)  # MB
        print(f"  Vị trí: {Colors.CYAN}{APK_PATH}{Colors.END}")
        print(f"  Kích thước: {Colors.CYAN}{file_size:.2f} MB{Colors.END}")
        
        return True
        
    except Exception as e:
        print_colored(f"Lỗi khi build: {e}", Colors.RED, bold=True)
        import traceback
        traceback.print_exc()
        return False


def create_version_json(version: str, build_number: int, force_update: bool, apk_file_id: str):
    """
    Tạo file version.json với thông tin cập nhật
    
    Args:
        version: Phiên bản (ví dụ: "1.1.0")
        build_number: Số build
        force_update: Có bắt buộc update không
        apk_file_id: File ID của APK trên Drive
    """
    release_notes = input("Nhập release notes (các tính năng mới, mỗi dòng một tính năng, nhấn Enter 2 lần để kết thúc):\n")
    lines = [release_notes]
    while True:
        line = input()
        if line == "":
            break
        lines.append(line)
    
    release_notes = "\n".join(lines)
    
    data = {
        "latest_version": version,
        "build_number": build_number,
        "force_update": force_update,
        "update_url": f"https://drive.google.com/file/d/{apk_file_id}/view?usp=sharing",
        "release_notes": release_notes or f"Phiên bản {version} - Cập nhật mới"
    }
    
    with open(VERSION_JSON_PATH, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    print_colored(f"✓ Đã tạo version.json", Colors.GREEN)
    print(f"  Version: {Colors.CYAN}{version}{Colors.END}")
    print(f"  Build: {Colors.CYAN}{build_number}{Colors.END}")
    print(f"  Force Update: {Colors.CYAN}{force_update}{Colors.END}")


def update_update_service_dart(version_json_file_id: str):
    """
    Cập nhật FILE_ID trong UpdateService.dart
    
    Args:
        version_json_file_id: File ID của version.json trên Drive
    """
    if not UPDATE_SERVICE_PATH.exists():
        print_colored(f"Lỗi: Không tìm thấy {UPDATE_SERVICE_PATH}", Colors.RED, bold=True)
        return False
    
    with open(UPDATE_SERVICE_PATH, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Thay thế YOUR_FILE_ID bằng file_id thực tế
    old_pattern = "YOUR_FILE_ID"
    new_url = f"https://drive.google.com/uc?export=download&id={version_json_file_id}"
    
    if old_pattern in content:
        content = content.replace(
            f"https://drive.google.com/uc?export=download&id={old_pattern}",
            new_url
        )
        
        with open(UPDATE_SERVICE_PATH, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print_colored(f"✓ Đã cập nhật FILE_ID trong UpdateService.dart", Colors.GREEN)
        print(f"  URL mới: {Colors.CYAN}{new_url}{Colors.END}")
        return True
    else:
        print_colored(f"Warning: Không tìm thấy YOUR_FILE_ID trong file", Colors.YELLOW)
        return False


def main():
    """Main function - Entry point của script"""
    parser = argparse.ArgumentParser(
        description='Build Flutter APK và upload lên Google Drive',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ví dụ:
  # Build và upload với version mới, bắt buộc update
  python build_and_upload.py --version 1.1.0 --build-number 2 --force-update
  
  # Build và upload không bắt buộc
  python build_and_upload.py --version 1.0.1 --build-number 3
  
  # Chỉ build không upload
  python build_and_upload.py --version 1.1.0 --build-only
        """
    )
    
    parser.add_argument(
        '--version', '-v',
        type=str,
        required=True,
        help='Phiên bản mới (ví dụ: 1.1.0)'
    )
    parser.add_argument(
        '--build-number', '-b',
        type=int,
        required=True,
        help='Số build (phải lớn hơn version hiện tại)'
    )
    parser.add_argument(
        '--force-update', '-f',
        action='store_true',
        help='Bật chế độ bắt buộc cập nhật'
    )
    parser.add_argument(
        '--build-only',
        action='store_true',
        help='Chỉ build APK không upload'
    )
    parser.add_argument(
        '--update-json-only',
        action='store_true',
        help='Chỉ upload version.json (giả sử APK đã tồn tại)'
    )
    
    args = parser.parse_args()
    
    print_colored("\n" + "="*60, Colors.GREEN, bold=True)
    print_colored("FLUTTER BUILD & GOOGLE DRIVE UPLOAD", Colors.GREEN, bold=True)
    print_colored("="*60, Colors.GREEN, bold=True)
    print(f"\n  Version: {Colors.CYAN}{args.version}{Colors.END}")
    print(f"  Build Number: {Colors.CYAN}{args.build_number}{Colors.END}")
    print(f"  Force Update: {Colors.CYAN}{args.force_update}{Colors.END}")
    print(f"  Build Only: {Colors.CYAN}{args.build_only}{Colors.END}")
    
    # Bước 1: Build APK
    if not args.update_json_only:
        if not build_flutter_apk():
            print_colored("\nBuild thất bại! Dừng quy trình.", Colors.RED, bold=True)
            sys.exit(1)
        
        if args.build_only:
            print_colored("\n✓ Build hoàn tất! (Không upload)", Colors.GREEN, bold=True)
            print(f"  APK location: {Colors.CYAN}{APK_PATH}{Colors.END}")
            sys.exit(0)
    
    # Bước 2: Upload lên Google Drive
    print_colored("\n" + "="*60, Colors.CYAN, bold=True)
    print_colored("UPLOAD LÊN GOOGLE DRIVE", Colors.CYAN, bold=True)
    print_colored("="*60, Colors.CYAN, bold=True)
    
    try:
        service = get_google_drive_service()
        
        apk_file_id = None
        
        # Upload APK
        if not args.update_json_only:
            apk_file_id = upload_to_drive(
                service,
                APK_PATH,
                f'app-release-v{args.version}.apk',
                'application/vnd.android.package-archive'
            )
        else:
            # Nếu chỉ update json, hỏi user nhập APK file ID
            apk_file_id = input("Nhập APK File ID (từ Google Drive): ").strip()
        
        # Tạo và upload version.json
        print_colored("\n--- Tạo version.json ---", Colors.YELLOW)
        create_version_json(args.version, args.build_number, args.force_update, apk_file_id)
        
        version_json_file_id = upload_to_drive(
            service,
            VERSION_JSON_PATH,
            'version.json',
            'application/json'
        )
        
        # Bước 3: Cập nhật FILE_ID trong UpdateService.dart
        print_colored("\n--- Cập nhật code ---", Colors.YELLOW)
        update_update_service_dart(version_json_file_id)
        
        # Hoàn tất
        print_colored("\n" + "="*60, Colors.GREEN, bold=True)
        print_colored("HOÀN TẤT!", Colors.GREEN, bold=True)
        print_colored("="*60, Colors.GREEN, bold=True)
        print(f"\n{Colors.CYAN}Tóm tắt:{Colors.END}")
        print(f"  ✓ APK uploaded: {Colors.BLUE}https://drive.google.com/file/d/{apk_file_id}/view{Colors.END}")
        print(f"  ✓ version.json uploaded: {Colors.BLUE}https://drive.google.com/file/d/{version_json_file_id}/view{Colors.END}")
        print(f"  ✓ UpdateService.dart đã được cập nhật")
        print(f"\n{Colors.YELLOW}Lưu ý:{Colors.END}")
        print(f"  - Commit và push code để cập nhật FILE_ID mới")
        print(f"  - Người dùng sẽ thấy dialog cập nhật khi mở app")
        
    except Exception as e:
        print_colored(f"\nLỗi: {e}", Colors.RED, bold=True)
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
