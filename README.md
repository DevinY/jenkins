# D-Laravel jenkins image

第一次執行，您可透過make_ci_workspace.sh建立，jenkins的工作目錄

執行:(幫您在host端建一個目錄，給container掛載用)
./make_ci_workspace.sh

使用(-d 放入背景執行):
docker-compose up -d

第一次執行啟動後，開啟localhost:8080

會看見需要一組Unlock Jenkins的解鎖密碼，可透過docker-compose logs查看

如果是加入-d參數，我們可以用查看。

docker-compose logs ci

如需資料庫等，建議可使用D-Laravel的架構進行。
D-Laravel為我建立的另一個repo，使用docker-compose的Laravel開發環境。

當然，這個jenkins的環境不需要D-Laravel也是可以執行及使用的。
