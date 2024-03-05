#!/bin/bash
cd /app || exit

# SVN 저장소에서 최신 코드 업데이트
svn update --username=zerosial --password='renag1010!@' --non-interactive --trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other

echo $PATH
which npm

export PATH=$PATH:/usr/local/bin

# 업데이트된 코드를 바탕으로 문서 재생성
npm run docs

# 문서 생성 완료 메시지 출력
echo "Documentation has been updated."