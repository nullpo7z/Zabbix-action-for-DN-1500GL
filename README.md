# Zabbix-action-for-DN-1500GL
Zabbix Alart script for isa's DN-1500GL (3-light model)

## usage
1. alert.shをZabbixサーバーに配置
2. スクリプトの登録
   タイプ: スクリプト
   次で実行: Zabbixサーバー
   コマンド: alert.sh {EVENT.NSEVERITY} {EVENT.VALUE} {EVENT.UPDATE.STATUS}
4. トリガーアクションの登録
   条件
     タイプ: トリガーの深刻度
     オペレーター: 以上
     深刻度: 未分類
   実行内容, 復旧時の実行内容, 更新時の実行内容に2のスクリプトを登録
