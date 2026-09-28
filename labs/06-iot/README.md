# W6：模擬設備與 MQTT

目標：使模擬設備發布事件，consumer 寫入平台，UI 可查。先不用硬體。

前置：完成上一階段或由 Git／備份重建；身分驗證通過；填妥本次資源與回收清單。

方法：學習 MQTT QoS、client ID、裝置憑證及 IoT topic policy；device/<device_id>/events 作為課堂 topic 契約。裝置認證與人員登入分開。

公開驗收：真正裝置身分 pub/sub；其他設備 topic 被拒；consumer 寫入與 UI 查詢；禁止用管理者 CLI publish 冒充裝置權限驗收。

交付：自己的程式與設定、可重現步驟、成功與拒絕／故障證據、一次修正及原因、成本與回收證據。
在 [報告模板](../../reports/TEMPLATE.md) 填入本次實際觀察；未測寫未測。
主要參考：[AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/)、[Boto3](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)。
