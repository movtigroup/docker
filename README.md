# 🐳 Docker Mirror Repository by Movti Group

این مخزن شامل اسکریپت‌ها و تنظیمات مورد نیاز برای نصب و استفاده از Docker **بدون نیاز به VPN** و با بهره‌گیری از **mirrorهای داخلی و به‌روز** مدیریت‌شده توسط **Movti Group** است. تمامی پکیج‌های Docker و imageهای آن از طریق سرورهای کش شده و پایدار قابل دانلود هستند.

---

## 🚀 نصب و راه‌اندازی

### 1. Ubuntu (توصیه شده)

اگر از سیستم‌عامل **Ubuntu** استفاده می‌کنید، کافیست دستور زیر را اجرا کنید. این اسکریپت به‌طور خودکار:
- Docker را از مخزن mirror نصب می‌کند
- mirror imageها را پیکربندی می‌کند
- نیازی به هیچ تنظیم اضافه‌ای نیست

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/install.sh | sh
```

### 2. سایر توزیع‌های لینوکس

اگر از توزیع دیگری غیر از Ubuntu استفاده می‌کنید (مانند Debian، CentOS، Arch و ...):
1. ابتدا **Docker را به روش رسمی** روی سیستم خود نصب کنید.
2. سپس دستور زیر را برای اضافه کردن mirror imageهای Docker و دور زدن تحریم‌ها اجرا کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/mirror.sh | sh
```

این اسکریپت فایل `daemon.json` را با mirrorهای Movti Group پیکربندی کرده و سرویس Docker را مجدداً راه‌اندازی می‌کند.

### 3. Docker Desktop (Windows / macOS)

اگر از **Docker Desktop** روی ویندوز یا مک استفاده می‌کنید:
1. به **Settings** (تنظیمات) بروید.
2. بخش **Docker Engine** را انتخاب کنید.
3. متن زیر را در فایل `daemon.json` جای‌گذاری کنید.
4. روی **Apply & Restart** کلیک کنید.

```json
{
  "registry-mirrors": [
    "https://docker.abrha.net"
  ]
}
```

---

## 🐧 Alpine Mirror

Movti Group همچنین یک **mirror به‌روز برای Alpine Linux** در دسترس قرار داده است. می‌توانید از آن در Dockerfile یا مستقیماً روی سیستم Alpine استفاده کنید.

### نمونه Dockerfile برای نصب Nginx از mirror Movti Group (بر پایه Alpine)

```dockerfile
FROM alpine

# اضافه کردن mirror Movti Group برای Alpine
RUN echo https://mirror.arvancloud.ir/alpine/v$(echo $(cat /etc/alpine-release) | awk -F . '{print $1"."$2}')/main > /etc/apk/repositories
RUN echo https://mirror.arvancloud.ir/alpine/v$(echo $(cat /etc/alpine-release) | awk -F . '{print $1"."$2}')/community >> /etc/apk/repositories

# نصب Nginx (به‌عنوان مثال)
RUN apk update && apk add nginx

CMD nginx -g "daemon off;"
```

> **نکته:** نسخه‌ی Alpine به‌طور خودکار از روی فایل `/etc/alpine-release` تشخیص داده می‌شود.

---

## 📡 لیست mirrorهای موجود

| آدرس mirror | کاربرد |
|-------------|--------|
| `https://docker.abrha.net` | mirror اصلی Docker Hub (برای کشیدن imageها) |
| `https://docker.arvancloud.ir` | mirror پشتیبان Docker Hub |
| `https://mirror.arvancloud.ir/alpine/...` | mirror پکیج‌های Alpine Linux |

---

## 📚 نیازمندی‌ها

- اتصال اینترنت (بدون نیاز به VPN)
- دسترسی `sudo` برای نصب و تغییر تنظیمات سیستم

---

## 🤝 مشارکت

اگر پیشنهاد یا بهبودی دارید، خوشحال می‌شویم Pull Request شما را ببینیم. همچنین می‌توانید issue ثبت کنید.

---

## 📜 مجوز

این پروژه تحت مجوز MIT منتشر شده است.
