# D-Laravel jenkins image

可以給D-Laravel一起使用的jenkins image.

第一次執行，您可透過make_ci_workspace.sh建立，jenkins的工作目錄

執行:
./make_ci_workspace.sh

使用(-d 放入背景執行):

docker-compose up -d


第一次執行時，後，開啟localhost:8080
會看見需要一組Unlock Jenkins的啟用密碼，可透過logs查看
如果是加入-d參數，我們可以用查看。

docker-compose logs ci

如需資料庫等，建議可使用D-Laravel的架構進行。
