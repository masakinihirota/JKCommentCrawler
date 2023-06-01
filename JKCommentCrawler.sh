#!/bin/bash

# Cron の設定例
## 毎日 00:01・00:15 (予備)・12:01・12:15 (予備) に実行
# 01 00 * * * sudo -u ubuntu /home/ubuntu/JKCommentCrawler/JKCommentCrawler.sh cron_daily
# 15 00 * * * sudo -u ubuntu /home/ubuntu/JKCommentCrawler/JKCommentCrawler.sh cron_daily
# 01 12 * * * sudo -u ubuntu /home/ubuntu/JKCommentCrawler/JKCommentCrawler.sh cron_daily
# 15 12 * * * sudo -u ubuntu /home/ubuntu/JKCommentCrawler/JKCommentCrawler.sh cron_daily
## 5分おきに実行
# */5 * * * * sudo -u ubuntu /home/ubuntu/JKCommentCrawler/JKCommentCrawler.sh cron_minutes

# 現在時刻
current_time=`date +"%Y/%m/%d %H:%M"`

# 自身のスクリプトのフルパスを取得
SCRIPT_PATH="$(readlink -f "$0")"

# スクリプトが存在するディレクトリのパスを取得
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# ログフォルダがなければ作成
if [ ! -d ${SCRIPT_DIR}/log ]; then
    mkdir ${SCRIPT_DIR}/log
fi

# JKCommentCrawler を実行
# Cron（5分ごと）
if [[ $1 = 'cron_minutes' ]]; then

    # 今日分の JKCommentCrawler を実行
    echo 'JKCommentCrawler.sh (Cron minutes)'
    ${SCRIPT_DIR}/.venv/bin/python ${SCRIPT_DIR}/JKCommentCrawler.py all `date +"%Y/%m/%d"` \
    1>  ${SCRIPT_DIR}/log/minutes.log \
    2>> ${SCRIPT_DIR}/log/minutes.error.log

# Cron（1日ごと）
elif [[ $1 = 'cron_daily' ]]; then

    # 前日分の JKCommentCrawler を実行（取りこぼし防止）
    ## --force パラメータを付けると、以前取得したログよりサイズが小さくても強制的に保存する
    ## ニコ生の実況番組の放送終了後にスパム判定されたコメント (特に AA) がごっそり削除されることがあり、
    ## それによって新しいログが保存されなくなる事態を避ける
    echo 'JKCommentCrawler.sh (Cron daily)'
    ${SCRIPT_DIR}/.venv/bin/python ${SCRIPT_DIR}/JKCommentCrawler.py all `date -d '-1 day' +"%Y/%m/%d"` --force \
    1>  ${SCRIPT_DIR}/log/daily.log \
    2>> ${SCRIPT_DIR}/log/daily.error.log

# 通常実行
else
    echo 'JKCommentCrawler.sh (Nornal)'
    ${SCRIPT_DIR}/.venv/bin/python ${SCRIPT_DIR}/JKCommentCrawler.py all `date +"%Y/%m/%d"`
fi

# Hugging Face (KakologArchives) に commit & push する
cd ${SCRIPT_DIR}/kakolog/
rm .git/index.lock
git add .
git commit -m "Add kakolog until ${current_time}"
git push

# 不要な LFS オブジェクトを削除する
## --verify-remote で、リモートに存在することを確認してから削除する
git lfs prune --recent --verify-remote
