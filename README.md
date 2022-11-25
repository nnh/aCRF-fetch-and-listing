# aCRF-fetch-and-listing
## 仕様
aCRF fetch and listing - Google ドキュメント  
https://docs.google.com/document/d/1VIDNu52ukYVhh0xlitPxDEc3gJs2uPOrA7hjZTxtbIw  
## 動作条件
- macOSで実行すること。  
- aws cliがインストールされており、使用できること。  
- 入力元サイトにアクセスできる環境であること。  
## スクリプト実行手順
- ./input_base_urlに入力元サイトのURLを`https://...com/`のように記載する。  
- ./output_base_urlにリンク先サイトのURLを`https://...com/`のように記載する。  
- ターミナルで`sh スクリプト名 'ユーザー名' '試験名'`と打って実行する。試験名はURL内のものと同一の文字列を入力する。  
コマンド実行例  
`cd ~/Documents/GitHub/aCRF-fetch-and-listing/programs/`  
`sh get_acrl.sh 'testmail@example.com' 'testTrial'`  
- ./output/試験名フォルダとaws s3の指定されたバケットにダウンロードされたファイルが格納される。  
## acrf.jp修正手順  
- ./output/試験名フォルダ/index.html（define.xmlの場合はxml_index.html）をテキストエディタで開く。
- ページの該当箇所（新規追加の場合は左クリック二回→埋め込み→Webからの埋め込み）に上記情報を貼り付ける。  
