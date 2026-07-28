 docker ps
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
 myu@Minkyuui-MacBookPro  ~/Documents/codyssey/ex/01   main ±
 docker rmi workstation-web:1.0
Error response from daemon: conflict: unable to delete workstation-web:1.0 (must be forced) - container a90cfe6e9f26 is using its referenced image 5836ce31c3c4

- ps는 현재 실행중인 컨테이너만 보여줌 
- docker stop하면 프로세스 종료 -> ps에선 안보임
- docker ps -a -> 종료된 컨테이너까지 모두 표시
    - 종료된 컨테이너도 다시 실행 가능해야함, 그래서 이미지 삭제는 안됨
    - 왜냐, 그 컨테이너가 종료되었지만 해당 이미지 참조중이니까
    - 그래서 이미지 지울려면 컨테이너 먼저 지우기 


- docker rm [] -> docker rmi []
- docker container prune -> 컨테이너 전체 삭제

docker run hello-world 
- 이거 그냥 도커 잘 깔았는지 테스트 명령어인듯
https://hub.docker.com/_/hello-world


- exec 
docker exec -it volume-test-1 bash

- volume 
docker volume create lab-data

docker v 연걸 -> -v lab-data:/data 
- docker volume 실제 부분
데이터는 네 Mac의 실제 디스크 공간을 사용해서 저장된다.
하지만 Docker Desktop은 macOS 위에서 작은 Linux VM을 실행한다.
pop 볼륨은 그 Linux VM 내부의 Docker 저장 영역에 관리된다.
따라서 Mountpoint에 나온 경로는 macOS 경로가 아니라 Linux VM 내부 경로다.


- docker compose config -> compose파일 검사


docker compose exec web wget -qO- http://backend:8000/