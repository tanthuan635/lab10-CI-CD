# Thiết lập CI/CD trên Jenkins Windows

Pipeline trong dự án thực hiện năm việc: lấy mã nguồn bằng Jenkins SCM, cài dependency tái lập với `npm ci`, chạy kiểm thử, build ứng dụng React, sau đó sao lưu bản đang chạy và deploy bản mới bằng `robocopy`.

## 1. Thay các placeholder

Trước khi chạy, bổ sung các thông tin cá nhân còn trống:

- `YOUR_NGROK_SUBDOMAIN` trong cấu hình webhook;
- họ tên và MSSV trong `THONG_TIN_SINH_VIEN.md`.

Repository của bài đã được xác định là
`https://github.com/tanthuan635/lab10-CI-CD.git`, nhánh `main`.

File `.env.example` chỉ là mẫu cấu hình. Jenkins không tự đọc file `.env`; các đường dẫn deploy được khai báo bằng tham số của job để có thể thay đổi an toàn từ giao diện Jenkins.

## 2. Chuẩn bị máy Windows

Cài các thành phần sau:

1. **Eclipse Temurin JDK 21 x64**, sau đó cấu hình biến môi trường `JAVA_HOME`;
2. Jenkins trên Windows và kiểm tra được `http://localhost:8080`;
3. Git for Windows;
4. ngrok;
5. các plugin Jenkins **Git**, **Pipeline**, **NodeJS** và **GitHub**; **Blue Ocean** là tùy chọn.

PDF ban đầu ghi JDK 11/17, nhưng Jenkins 2.568.2 LTS yêu cầu Java 21 hoặc 25.
Vì vậy cấu hình này dùng Java 21 LTS để Jenkins có thể khởi động ổn định.

Trong **Manage Jenkins → Tools** (ở bản cũ là **Global Tool Configuration**):

- thêm Git tên `Default Git`, đường dẫn `C:\Program Files\Git\bin\git.exe`;
- thêm NodeJS installation tên chính xác `NodeJS 24`, chọn tự động cài một bản Node.js
  24 LTS. Jenkinsfile tham chiếu đúng tên này. Không chọn Node.js 20 vì dòng này
  đã hết hỗ trợ từ tháng 3/2026.

Jenkinsfile dùng agent khả dụng trên máy cục bộ và kiểm tra để từ chối hệ điều hành không phải Windows. Đăng nhập bằng đúng tài khoản chạy dịch vụ Jenkins rồi kiểm tra `git`, `node`, `npm` và `robocopy` đều có trong `PATH`. Sau khi sửa `PATH`, cần khởi động lại dịch vụ Jenkins.

Tài khoản dịch vụ Jenkins phải có quyền Modify trên đúng hai thư mục deploy và backup. Ví dụ, chạy PowerShell bằng quyền quản trị và thay tài khoản/path cho phù hợp:

```powershell
New-Item -ItemType Directory -Force 'C:\JenkinsDeploy\ReactApp'
New-Item -ItemType Directory -Force 'C:\JenkinsDeploy\Backups'
icacls 'C:\JenkinsDeploy' /grant 'NT AUTHORITY\SYSTEM:(OI)(CI)M' /T
```

Máy thực hiện bài này chọn chạy dịch vụ Jenkins bằng `LocalSystem`, nên ví dụ cấp
quyền trên phù hợp. Đây là tài khoản chạy dịch vụ Windows, tách biệt với tài khoản
quản trị được tạo trong giao diện web Jenkins sau khi mở khóa lần đầu.

## 3. Tạo Jenkins job

### Cách A — Freestyle đúng yêu cầu trong PDF

1. Push toàn bộ dự án lên GitHub.
2. Chọn **New Item**, nhập `React_Build_Deploy`, rồi chọn **Freestyle project**.
3. Trong **Source Code Management**, chọn **Git**, nhập URL repository và branch
   `*/main`.
4. Trong **Build Environment**, bật **Provide Node & npm bin/ folder to PATH** và
   chọn `NodeJS 24`.
5. Trong **Build Triggers**, bật **GitHub hook trigger for GITScm polling**.
6. Trong **Build Steps**, thêm **Execute Windows batch command**:

```bat
set "DEPLOY_DIR=C:\JenkinsDeploy\ReactApp"
set "BACKUP_DIR=C:\JenkinsDeploy\Backups"
call "%WORKSPACE%\scripts\deploy.bat"
```

Lệnh trên tự chạy `npm ci`, kiểm thử, build, backup và deploy. PDF dùng ổ `D:` làm
ví dụ, nhưng máy thực hiện bài không có ổ này nên dự án dùng
`C:\JenkinsDeploy` và gọi script trực tiếp từ Jenkins workspace.

### Cách B — Pipeline bằng Jenkinsfile (bổ sung)

1. Push toàn bộ dự án, gồm `Jenkinsfile`, `scripts/deploy.bat` và `package-lock.json`, lên GitHub.
2. Trong Jenkins chọn **New Item → Pipeline**.
3. Ở phần **Pipeline**, chọn **Pipeline script from SCM**.
4. Chọn **Git**, nhập `https://github.com/tanthuan635/lab10-CI-CD.git`, chọn credentials nếu repository private, và đặt branch `*/main`.
5. Đặt **Script Path** là `Jenkinsfile`, lưu job và chạy **Build Now** một lần.
6. Ở lần chạy kế tiếp, kiểm tra các tham số `DEPLOY_ENABLED`, `DEPLOY_DIR`, `BACKUP_DIR`; thay đường dẫn nếu máy không có ổ `D:`.

Pipeline cố ý dùng `checkout scm`. Không thêm `git pull`, `git reset --hard` hoặc lệnh thay đổi branch vào script build vì Jenkins SCM chịu trách nhiệm quản lý checkout của workspace job.

## 4. Kết nối GitHub webhook qua ngrok

Đăng nhập ngrok và mở tunnel tới Jenkins:

```powershell
ngrok config add-authtoken YOUR_NGROK_AUTHTOKEN
ngrok http 8080
```

Sao chép URL HTTPS mà ngrok cung cấp, ví dụ `https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app`. Trong GitHub repository mở **Settings → Webhooks → Add webhook** rồi đặt:

- Payload URL: `https://YOUR_NGROK_SUBDOMAIN.ngrok-free.app/github-webhook/` (giữ dấu `/` cuối);
- Content type: `application/json`;
- Events: **Just the push event**;
- Active: bật.

Trong cấu hình Jenkins job bật **GitHub hook trigger for GITScm polling**. Push một commit lên branch đã cấu hình và kiểm tra GitHub báo delivery `2xx`, sau đó Jenkins phải tạo build mới.

URL ngrok miễn phí có thể đổi sau khi khởi động lại, trừ khi tài khoản có domain cố định. Khi URL đổi, cập nhật lại Payload URL. Chỉ mở tunnel trong lúc demo; không công khai Jenkins chưa được bảo vệ bằng đăng nhập/phân quyền.

## 5. Hành vi deploy và kiểm tra

Sau `npm run build`, Pipeline ưu tiên output `build/index.html` của dự án này và chỉ
dùng `dist/index.html` làm phương án tương thích dự phòng. Artifact được lưu trong
Jenkins trước khi deploy.

`scripts/deploy.bat` sẽ:

1. ưu tiên `%WORKSPACE%` của Jenkins, hoặc tự tìm project root khi chạy thủ công;
2. từ chối đường dẫn root, đường dẫn trùng/lồng nhau và build thiếu `index.html`;
3. tạo backup UTC có dạng `yyyyMMdd_HHmmss_fffZ` nếu đã có bản deploy;
4. đồng bộ build mới bằng `robocopy /MIR /XJ` (không đi theo junction);
5. coi exit code `0`–`7` của `robocopy` là thành công và từ `8` trở lên là lỗi.

Có thể chạy trọn quy trình thủ công từ Command Prompt:

```bat
scripts\deploy.bat
```

Hoặc chỉ deploy một build đã có vào đường dẫn tùy chỉnh:

```bat
scripts\deploy.bat "%CD%\build" "C:\JenkinsDeploy\ReactApp" "C:\JenkinsDeploy\Backups"
```

Khi deploy lỗi, Jenkins dừng ngay; nếu trước đó có dữ liệu, log sẽ chỉ rõ thư mục backup để khôi phục thủ công.
