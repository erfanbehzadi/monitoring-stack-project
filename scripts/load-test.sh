#!/bin/bash

echo "🚀 شروع تست بار روی Nginx..."

# تست سبک
echo "تست ۱: ۲۰۰ درخواست"
ab -n 200 -c 50 http://localhost/ 2>/dev/null || \
curl -s -o /dev/null http://localhost/

# تست سنگین‌تر
echo "تست ۲: ۱۰۰۰ درخواست (ممکنه چند ثانیه طول بکشه)"
ab -n 1000 -c 100 http://localhost/ 2>/dev/null || \
for i in {1..300}; do curl -s -o /dev/null http://localhost/ & done

echo "✅ تست تمام شد. برو Grafana و داشبوردها رو رفرش کن!"
