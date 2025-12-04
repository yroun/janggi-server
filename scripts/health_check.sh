#!/bin/bash

# 8001번 포트가 뜰 때까지 최대 60초 대기
for i in {1..12}; do
    # 로컬호스트 8001번의 루트(/)를 찔러서 HTTP 200이 나오는지 확인
    HTTP_CODE=$(curl --write-out '%{http_code}' --silent --output /dev/null http://127.0.0.1:8001/)

    if [ "$HTTP_CODE" -eq 200 ]; then
        echo "✅ Server is up and running on port 8001!"
        exit 0
    fi

    echo "⏳ Waiting for server to start... ($i/12)"
    sleep 5
done

echo "❌ Server failed to start."
exit 1
