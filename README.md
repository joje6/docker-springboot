# docker-springboot

## 빌드
```sh
$ docker build --force-rm --platform linux/amd64 -t springboot .   
```

## 실행
```sh
$ docker run --name springboot -d -p 8080:8080 springboot 
```
