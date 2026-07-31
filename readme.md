# QE4heat

加熱（Heating）模擬 DFT 計算自動化系統。

對系統在不同溫度下進行 DFT 計算，使用 crontab 定期監控和提交工作。

---

## 程式功能說明

### 工作流程

```
基底結構 → 不同溫度設定 → QE 批量提交 → Crontab 監控 → 結果收集
```

### 核心腳本

| 腳本 | 功能 |
|---|---|
| `make_base4heat.pl` | 生成加熱模擬基底 |
| `submit_allbaseTjobs.pl` | 提交所有溫度點工作 |
| `submit4newHeat.pl` | 提交新加熱工作 |
| `check_QEjobs4heating.pl` | 檢查加熱工作狀態 |
| `data_collect4Heat.pl` | 收集加熱結果 |
| `collect_folders4heat.pl` | 整理加熱目錄 |
| `softlink4training.pl` | 為訓練建立符號連結 |
| `updated_QEin.pl` | 更新 QE 輸入參數 |
| `create_crontab.pl` | 自動建立 crontab 監控 |
| `modsh4queue.sh` | 修改排隊工作的 slurm 腳本 |
| `submit4Allqueuing.pl` | 重新提交所有排隊工作 |
| `heating_bash.sh` | 加熱 bash 腳本 |

---

## 依賴環境

| 項目 | 需求 |
|---|---|
| 語言 | Perl 5.x |
| DFT | Quantum ESPRESSO |
| 排程 | Slurm + Crontab |

---

## 使用方法

```bash
perl make_base4heat.pl       # 生成基底
perl submit_allbaseTjobs.pl  # 提交各溫度點
perl create_crontab.pl       # 建立定期監控
perl check_QEjobs4heating.pl # 手動檢查狀態
perl data_collect4Heat.pl    # 收集結果
```

---

## AI Agent 操控指南

```
任務: 執行多溫度加熱模擬
步驟:
1. perl make_base4heat.pl 生成基底
2. perl submit_allbaseTjobs.pl 提交工作
3. perl create_crontab.pl 建立監控
4. perl check_QEjobs4heating.pl 檢查進度
5. 完成後: perl data_collect4Heat.pl 收集結果
```
