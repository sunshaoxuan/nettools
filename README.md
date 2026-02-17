# NetTools

PowerShell ベースのネットワークツールキットです。  
メインメニューから NAT ポートマッピングのサブツールを呼び出します。

## 起動

```powershell
.\Invoke-NetToolkit.ps1
```

## 言語切替

```powershell
.\Invoke-NetToolkit.ps1 -Lang ja
.\Invoke-NetToolkit.ps1 -Lang zh
.\Invoke-NetToolkit.ps1 -Lang en
```

既定は `ja` です。

## 機能

- ルートメニュー: `NAT` / `Firewall`
- NAT ツール:
  - ポートマッピング一覧表示（表形式）
  - ポートマッピング作成
  - ポートマッピング削除
- Firewall ツール:
  - 指定ポートの開放状態を確認
  - 指定ポートを快速開放（受信許可ルール作成）
  - 指定ポートの開放ルールを快速削除

実装は Windows `netsh interface portproxy` を利用しています。  
作成・削除は管理者権限で実行してください。
