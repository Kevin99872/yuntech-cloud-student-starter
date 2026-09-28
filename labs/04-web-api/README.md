# W4：平台介面與 API

目標：建立設備／事件 UI 和 API，部署到可重建的 EC2；輸入驗證、兩種測試角色、HTTPS、日誌與重啟。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：依 docs/system-contract.md 設計路由及狀態碼。採用成熟驗證元件；先走本機測試，再受限部署。HTTPS 憑證及管理通道由教師公布當次已驗證方式。

公開驗收：有效事件建立；無效輸入 400；缺少認證 401；無權操作 403；驗證 HTTPS 憑證與名稱；重啟後可服務且日誌不含秘密。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
