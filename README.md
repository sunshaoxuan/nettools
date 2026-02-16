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

- ルートメニュー: `NAT` ツールのみ表示
- NAT サブメニュー内:
  - ポートマッピング一覧表示（表形式）
  - ポートマッピング作成
  - ポートマッピング削除

実装は Windows `netsh interface portproxy` を利用しています。  
作成・削除は管理者権限で実行してください。
