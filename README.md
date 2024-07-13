# M1GPS

M1グランプリ（学内で行われる、個人開発イベント）で最優秀賞をいただいた、場所でしりとりをするアプリ

**概要**  
M1グランプリは、場所の名前でしりとりをしていき、入力した場所と前の場所の距離を計算することで、ポイントを取得し、競うことのできるゲームです。

**使用方法**  
1. アプリを起動し、ゲームを開始します。  
2. 2台のスマホで「PLAY」ボタンを押して、マッチングを行います。  
3. 場所の名前を入力して、しりとりを始めます。  
   - 前の場所よりも近い場所、または遠い場所を入力することで、より多くのポイントを獲得できます。  
   - 「近い場所」または「遠い場所」の指定はランダムで決まり、画面に表示されます。  
4. ターンを交代しながら、ゲームを進めます。  
5. 5ターン終了後、より多くのポイントを持っているプレイヤーが勝者となります。  

**機能**  
- **Google Places APIの使用**: 場所の名前を入力して場所の詳細情報や写真を取得します。  
- **MapKitの使用**: マップ上に場所の位置を表示します。  
- **リアルタイムチャット**: MultipeerConnectivityを使用してリアルタイムでメッセージを送信します。

**使用技術**  
- Swift  
- Xcode
