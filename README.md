# 🐳 Docker Mirror Repository by Movti Group

این مخزن شامل اسکریپت‌ها و تنظیمات مورد نیاز برای نصب و استفاده از Docker **بدون نیاز به VPN** و با بهره‌گیری از **mirrorهای داخلی و به‌روز** مدیریت‌شده توسط **Movti Group** است. تمامی پکیج‌های Docker و imageهای آن از طریق سرورهای کش شده و پایدار قابل دانلود هستند.

---

## 🚀 نصب و راه‌اندازی

### 1. نصب خودکار (توصیه شده برای اکثر توزیع‌ها)

این اسکریپت به‌طور خودکار توزیع لینوکس شما (Ubuntu, Debian, CentOS, Fedora, Arch و ...) را تشخیص داده و Docker را با تنظیمات بهینه و استفاده از میرورهای داخلی نصب می‌کند. همچنین برای دور زدن محدودیت‌های دریافت کلید، از متد **Insecure/No-Key** استفاده می‌کند.

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/install.sh | sudo bash
```

### 2. تنظیم میرور برای داکر نصب شده

اگر قبلاً Docker را نصب کرده‌اید و فقط می‌خواهید میرورهای Movti Group را به آن اضافه کنید تا تحریم‌ها را دور بزنید، از این دستور استفاده کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/movtigroup/docker/main/mirror.sh | sudo bash
```

این اسکریپت فایل `daemon.json` را با میرورهای زیر پیکربندی کرده و سرویس Docker را مجدداً راه‌اندازی می‌کند.

### 3. Docker Desktop (Windows / macOS)

اگر از **Docker Desktop** روی ویندوز یا مک استفاده می‌کنید:
1. به **Settings** (تنظیمات) بروید.
2. بخش **Docker Engine** را انتخاب کنید.
3. متن زیر را در آرایه `registry-mirrors` فایل `daemon.json` جای‌گذاری کنید.
4. روی **Apply & Restart** کلیک کنید.

```json
{
  "registry-mirrors": [
    "https://docker.ththt.ir",
    "https://docker.arvancloud.ir",
    "https://mirror2.chabokan.net",
    "https://docker.abrha.net"
  ]
}
```

---

## 📡 لیست mirrorهای موجود

| آدرس mirror | کاربرد | اولویت |
|-------------|--------|--------|
| `https://docker.ththt.ir` | mirror اصلی Docker Hub (جدید) | 1️⃣ |
| `https://docker.arvancloud.ir` | mirror پشتیبان | 2️⃣ |
| `https://mirror2.chabokan.net` | mirror پشتیبان و پکیج‌های سیستم‌عامل | 3️⃣ |
| `https://docker.abrha.net` | mirror پشتیبان | 4️⃣ |

---

## 📚 ویژگی‌ها

- **پشتیبانی از توزیع‌های مختلف:** Ubuntu, Debian, CentOS, RHEL, Fedora, Arch Linux.
- **نصب بدون کلید (No-Key):** حل مشکل اختلال در دریافت کلیدهای GPG مخازن داکر.
- **بدون نیاز به تغییر DNS یا VPN:** تمامی مراحل از داخل شبکه ایران قابل انجام است.

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

---

## 🤝 مشارکت

اگر پیشنهاد یا بهبودی دارید، خوشحال می‌شویم Pull Request شما را ببینیم. همچنین می‌توانید issue ثبت کنید.

---

## 📜 مجوز

این پروژه تحت مجوز MIT منتشر شده است.
