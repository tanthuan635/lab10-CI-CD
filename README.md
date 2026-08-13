# Bài thực hành 10 — CI/CD với Jenkins và GitHub

Ứng dụng React minh họa quy trình `push → webhook → test/build → deploy` theo đề
`Bai TH 10.pdf`. Dự án dùng Vite nhưng vẫn xuất bản build vào thư mục `build/`
để tương thích với `deploy.bat` trong đề.

## Chạy ứng dụng

Yêu cầu: Node.js 22.12 trở lên; cấu hình Jenkins của bài dùng Node.js 24 LTS.

```powershell
npm install
npm run dev
```

Trình duyệt sẽ mở tại địa chỉ Vite hiển thị trong terminal (thường là
`http://localhost:5173`).

## Kiểm thử và build

```powershell
npm test
npm run build
```

Sau khi build, bản production nằm trong `build/`.

## Thực hiện bài CI/CD

- Hướng dẫn cài Java, Jenkins, plugin, GitHub webhook và ngrok nằm tại
  [`docs/SETUP.md`](docs/SETUP.md).
- Script Windows mà Jenkins gọi nằm tại [`scripts/deploy.bat`](scripts/deploy.bat).
- Có thể dùng job Freestyle đúng đề hoặc job Pipeline với [`Jenkinsfile`](Jenkinsfile).

> Trước khi chạy Jenkins, cấu hình các tham số `DEPLOY_DIR` và `BACKUP_DIR` trong
> màn hình **Build with Parameters**. `.env.example` chỉ là mẫu tham khảo khi chạy
> script thủ công; Jenkins không tự đọc file `.env`.

## Nội dung cần cá nhân hóa trước khi nộp

1. Repository đã cấu hình: `https://github.com/tanthuan635/lab10-CI-CD.git` trên
   nhánh `main`.
2. Thông tin cá nhân đã điền trong `docs/THONG_TIN_SINH_VIEN.md`; file Word nộp bài
   đã được tạo với tên `2311554901_NguyenTanThuan.docx`.
3. Chụp Console Output của lần build thành công và màn hình thư mục triển khai.

Bài này được chuẩn bị theo hình thức **cá nhân (01 sinh viên thực hiện)**.
Jenkins chạy local tại `http://localhost:8080`, không sử dụng tài khoản Jenkins
riêng; tài khoản GitHub thực hiện bài là `tanthuan635`.

Lưu ý: đề mang tên **Bài thực hành 10** nhưng phần nộp bài ghi đường dẫn `Lab9`.
Nên xác nhận lại đường dẫn với giảng viên trước khi nộp.
