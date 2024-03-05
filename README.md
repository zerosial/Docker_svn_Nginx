### **Docker를 이용한 Node.js 및 Nginx 환경 구성 및 최적화 가이드**
![chrome_pAKVMbTrbG](https://github.com/zerosial/Docker_svn_Nginx/assets/97251710/a13a5da8-65e3-4e50-8423-0d6868f88a63)

### 개요

이 가이드는 Docker를 사용하여 Node.js 애플리케이션과 Nginx 서버를 구성하고, 효율적으로 배포하기 위한 전반적인 프로세스를 다룹니다. 특히 SVN에서 코드를 체크아웃하고, 문서를 생성하며, live-server를 이용한 로컬 개발 환경 설정에 초점을 맞춥니다. 또한, Docker Compose를 활용하여 여러 컨테이너를 관리하는 방법에 대해서도 설명합니다.

### 배포 파일 및 환경

![chrome_fgiy0ZuGHY](https://github.com/zerosial/Docker_svn_Nginx/assets/97251710/611703a4-9d50-4a05-90c5-dc2851e14668)


해당 폴더를 터미널 혹은 VSC를 통하여 열고
Docker가 설치된 상태로

빌드

`docker-compose build`

컨테이너 배포

`docker-compose up -d`

### 추가 설정

**SVN URL 및 정보 변경**

update_docs.sh 및 Dockerfile.node의 svn 체크아웃 및 업데이트 시 URL 아이디, 비밀번호, SSL 우회 명령어가 삽입되어 있습니다 해당 URL과 세부정보는 상황에 따라 수정하면 됩니다.

**포트 변경**

기본적으로 도커 내부에 8080에서 live-server가 호스팅되며 해당 컨테이너를 `nginx/default.conf` 를 통해 배포하게 됩니다. 포트 설정이 변경될 경우 해당 파일의 listen 부분에서 포트를 변경하고 **`docker-compose.yml`** 에서 추가적으로 8720:8720으로 작업된 부분을 수정하시면 됩니다.

**생성 주기 및 시간 관리**
`RUN (crontab -l ; echo "* * * * * /app/update_docs.sh >> /var/log/cron.log 2>&1") | crontab -` 위의 명령어를 통해 주기 등록됩니다.

**`* * * * *`**: 크론 스케줄 표현식으로, 5개의 별표(*)는 분, 시, 일, 월, 요일을 나타내며, 여기서 모두 별표로 설정되어 있으므로 매분마다 해당 명령을 실행하라는 의미입니다.

**`0 0 * * *`**: 이 표현은 매일 자정(0시 0분)에 명령을 실행하라는 의미입니다.

**`30 6 * * *`**: 이 표현은 매일 (6시 30분)에 명령을 실행하라는 의미입니다.

### 환경 설정

1. **Node.js 컨테이너 설정**
    - Node.js 기반의 Docker 이미지를 사용하여 애플리케이션 빌드 환경을 구성합니다.
    - **`WORKDIR`**을 **`/app`**으로 설정하여 애플리케이션의 작업 디렉토리를 지정합니다.
    - 필요한 시스템 패키지(**`subversion`**, **`cron`**)를 설치합니다.
    - SVN에서 프로젝트 코드를 체크아웃하고, 필요한 npm 패키지(**`live-server`**)를 글로벌로 설치합니다.
    - **`npm install`**을 실행하여 프로젝트 의존성을 설치합니다.
    - 문서 생성 스크립트(**`npm run docs`**)를 실행하여 프로젝트 문서를 생성합니다.
2. **Nginx 컨테이너 설정**
    - Nginx를 사용하여 Node.js 애플리케이션을 프록시하는 웹 서버 환경을 구성합니다.
    - Nginx의 설정 파일을 커스터마이즈하여 Node.js 애플리케이션으로 요청을 전달합니다.
    - 외부 요청을 처리할 수 있도록 포트 매핑을 구성합니다.
3. **Docker Compose를 이용한 서비스 관리**
    - **`docker-compose.yml`** 파일을 작성하여 Node.js와 Nginx 컨테이너를 정의하고 네트워크를 통해 연결합니다.
    - 볼륨 마운트를 사용하여 개발 중인 코드를 컨테이너와 동기화할 수 있지만, 볼륨 마운트가 프로덕션 빌드에 영향을 미치지 않도록 주의합니다.

### 문제 해결 및 최적화

1. **파일 누락 문제**
    - Docker Compose의 볼륨 마운트 설정으로 인해 컨테이너 내 파일이 호스트와 동기화되면서 기대한 파일이 누락될 수 있습니다. 해결책으로 볼륨 마운트 설정을 재검토하거나 개발과 배포 환경을 분리합니다.
    
    이번 환경의 경우 checkout 한 svn 파일이 도커 내 /app에 배치되지 않아 새부 설정을 확인하다 보니 Docker-compose에서 해당 부분이 발견되어 수정하였습니다.
    
    As-is
    
    ```json
    // As-is  
    	node-container:
        build: # Node.js 애플리케이션 빌드 설정
          context: .
          dockerfile: Dockerfile.node
        **volumes:
          - .:/app**
        networks:
          - mm-app-network # 사용할 네트워크 정의
    
    // To-be
    	node-container:
        build: # Node.js 애플리케이션 빌드 설정
          context: .
          dockerfile: Dockerfile.node
        networks:
          - mm-app-network # 사용할 네트워크 정의
    
    ```
    
2. **컨테이너 내부의 폴더 및 파일 확인 (log)**
    - 중간 중간 `RUN npm run docs && ls -la /app/docs` 와 같이 ls -la 명령어를 통해 빌드된 도커의 파일들을 확인하며  `/var/log/cron.log` 파일을 생성하는 로직을 통해 백그라운드에서 실행되는 cron이 정상 작동하는지 확인했습니다.
3. **환경 변수 및 PATH 설정**
    - 글로벌로 설치된 npm등의 패키지가 update_docs.sh에서 cron으로 재실행 될때 작동하지 않는 문제는 **`PATH`** 환경 변수 설정을 통해 해결할 수 있습니다. Dockerfile에서 환경 변수를 적절히 설정합니다.
4. **SVN의 SSL 만료 오류**
    - 해당 오류의 경우 update 및 checkout 시 마지막 명령어에 `--non-interactive --trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other` 를 추가함으로 해결하였습니다.
    

## 코드 별 설명

### **build-package.json 설명 및 주석**

**`build-package.json`** 파일은 특정 npm 패키지(**`jsdoc`**, **`minami`**, **`taffydb`**)의 설치와 문서 생성 스크립트를 정의합니다. 이 파일은 Docker 빌드 과정에서 사용되어, 프로젝트 문서화에 필요한 최소한의 의존성만을 관리합니다.

기존 package.json이 설치&빌드&테스트 등 문서화 작업에 관계 없는 패키지가 많아 builder-package.json 을 따로 만들고 기존 파일을 대체하는 방식으로 작성되었습니다.

```json
{
  "dependencies": {
    "jsdoc": "^4.0.2", // JSDoc 패키지, JavaScript 코드 문서화 도구
    "minami": "^1.2.3", // JSDoc 문서의 템플릿으로 사용될 Minami 스타일
    "taffydb": "^2.7.3" // JSDoc에서 사용되는 인메모리 데이터베이스
  },
  "scripts": {
    "docs": "jsdoc -c jsdoc.conf.json" // jsdoc 명령어를 이용해 문서를 생성하는 스크립트
  }
}

```

### **docker-compose.yml 설명 및 주석**

**`docker-compose.yml`** 파일은 Docker Compose를 사용하여 **`node-container`**와 **`nginx-container`** 서비스를 정의하고, 네트워크를 통해 이들을 연결합니다. 이 구성을 통해 Node.js 애플리케이션을 Nginx를 통해 서빙하는 아키텍처를 구현합니다.

```yaml
version: "3.8"

services:
  node-container:
    build: # Node.js 애플리케이션 빌드 설정
      context: .
      dockerfile: Dockerfile.node
    networks:
      - mm-app-network # 사용할 네트워크 정의

  nginx-container:
    build: # Nginx 서버 빌드 설정
      context: .
      dockerfile: Dockerfile.nginx
    ports:
      - "8720:8720" # 호스트와 컨테이너 간 포트 매핑
    depends_on:
      - node-container # node-container에 의존성 명시
    networks:
      - mm-app-network # 사용할 네트워크 정의

networks:
  mm-app-network: # 네트워크 정의
```

### **Dockerfile.node 설명 및 주석**

**`Dockerfile.node`**는 Node.js 기반의 애플리케이션을 빌드하고, 문서를 생성하기 위한 설정을 포함합니다.

```bash
# Node.js 기반 빌드 스테이지
FROM node:16.20.1

# 작업 디렉토리 설정
WORKDIR /app

# 필수 패키지 설치
RUN apt-get update && apt-get install -y subversion cron

# 애플리케이션 파일 및 설정 복사
COPY . /app

# SVN에서 프로젝트 코드 체크아웃
RUN svn checkout "svn url" --username="svn 아이디" --password='svn 암호' --non-interactive --trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other .

# 기존 package.json에서 필요없는 의존성을 빼고 필수 패키지만 설정
COPY build-package.json /app/package.json

# live-server 글로벌 설치
RUN npm install -g live-server

# 의존성 설치 및 문서 생성
RUN npm install
RUN npm run docs && ls -la /app/docs

# Cron 작업 설정 및 주기적인 문서갱신 관리파일
RUN chmod +x /app/update_docs.sh
RUN (crontab -l ; echo "* * * * * /app/update_docs.sh >> /var/log/cron.log 2>&1") | crontab -

# Live-server 실행 및 cron 시작
CMD cron -f & live-server /app/docs --port=8080 --host=0.0.0.0 --entry-file=index.html

```

### **Dockerfile.nginx 설명 및 주석**

**`Dockerfile.nginx`** 파일은 Nginx 웹 서버를 설정하고, 커스텀 Nginx 구성 파일을 컨테이너에 복사하는 과정을 정의합니다. 이 파일을 통해 Node.js 애플리케이션에 대한 프록시 서버로 Nginx를 구성하고, 외부 요청을 애플리케이션으로 전달할 수 있도록 설정합니다.

```
# Nginx 환경 설정
FROM nginx:alpine

# 'nginx:alpine' 이미지 사용: 이는 Nginx 웹 서버가 설치된 경량화된 Alpine Linux 기반 이미지입니다.
# Alpine Linux는 작은 이미지 크기와 보안, 간단한 구성으로 인해 Docker 컨테이너에 많이 사용됩니다.

# Nginx 구성 파일 복사
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# 'nginx/default.conf' 파일을 컨테이너의 '/etc/nginx/conf.d/default.conf' 위치로 복사합니다.
# 이 과정은 컨테이너 내부의 Nginx 설정을 사용자 정의 설정으로 대체합니다.
# 커스텀 구성 파일은 Nginx 서버의 동작 방식을 정의하며, 특히 Node.js 애플리케이션으로의 프록시 설정을 포함할 수 있습니다.

```

**`nginx/default.conf`** 파일 내부에 정의된 설정은 Nginx가 클라이언트로부터 받은 요청을 **`node-container`** 서비스의 8080 포트로 전달하도록 지정합니다. 이를 통해 Nginx는 정적 파일을 처리하고, 동적 요청은 Node.js 애플리케이션으로 전달하는 역할을 수행하게 됩니다. 또한, 요청의 헤더를 조작하여 애플리케이션으로 전달하기 전에 필요한 정보를 추가할 수 있습니다.

### **update_docs.sh 설명 및 주석**

**`update_docs.sh`** 스크립트는 SVN에서 최신 코드를 가져오고, 문서를 재생성하는 작업을 자동화합니다.

```bash
#!/bin/bash
cd /app || exit

# SVN 저장소에서 최신 코드 업데이트
svn update --username="svn 아이디" --password='svn 암호' --non-interactive --trust-server-cert-failures=unknown-ca,cn-mismatch,expired,not-yet-valid,other

# npm 전역설치 절대경로 추가
export PATH=$PATH:/usr/local/bin

# 업데이트된 코드를 바탕으로 문서 재생성
npm run docs

# 문서 생성 완료 메시지 출력
echo "Documentation has been updated."

```

### **nginx/default.conf 설명 및 주석**

**`nginx/default.conf`**는 Nginx 서버의 구성을 정의하며, Node.js 애플리케이션으로의 요청 프록싱을 설정합니다.

```
nginxCopy code
server {
    listen 8720; # Nginx가 8720 포트에서 리스닝

    location / {
        proxy_pass http://node-container:8080; # Node.js 애플리케이션으로 요청을 전달
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```
