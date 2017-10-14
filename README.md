# D-Laravel jenkins image

執行:
docker-compose up -d

第一次執行啟動後，開啟localhost:8080

會看見需要一組Unlock Jenkins的解鎖密碼，可透過docker-compose logs查看


其他: 

deviny/jenkins:7.1.10的Dockerfile使用官方(jenkins/jinkins:lts)的長期支援版本，
如果已pull過官方的，jenkins/jenkins:lts版本。
再重build時，請先重新pull最新版的jenkins/jenkins:lts版本。

可用如下指令重新pull
update.sh

