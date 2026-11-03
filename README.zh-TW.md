# Debian GNOME MacBookPro11,1 闔蓋背光控制

[English](README.md) | **繁體中文**

這是一個針對 **2013 年 13 吋 Retina MacBook Pro（MacBookPro11,1）**，在 **Debian 13 + GNOME** 環境下使用的闔蓋背光控制方案。

當筆電闔上螢幕時，自動關閉內建螢幕背光；重新開啟時，恢復先前的亮度。同時讓 Linux 系統在闔蓋時繼續運作，以便透過 SSH 或遠端桌面存取。

本專案的目標，是讓較舊款的 MacBook 在 Linux 環境下也能作為闔蓋運作的遠端主機使用，而不必因為闔蓋就讓系統進入休眠。

## 功能特色

- 闔蓋持續 1 秒後，自動關閉內建螢幕背光。
- 開蓋時恢復先前儲存的亮度。
- 在修改背光前重新確認 ACPI 螢幕狀態。
- 開蓋時加入短暫延遲，降低感應器狀態短暫變動造成的問題。
- 搭配適當的 `systemd-logind` 設定，讓系統在闔蓋時保持運作。
- 保留診斷紀錄，方便排查問題。

## 已測試環境

| 項目 | 測試配置 |
|---|---|
| 筆電 | 2013 年 13 吋 Retina MacBook Pro |
| 機型識別碼 | MacBookPro11,1 |
| 作業系統 | Debian 13 (Trixie) |
| 桌面環境 | GNOME |
| 背光介面 | `/sys/class/backlight/acpi_video0` |
| 螢幕開闔狀態 | `/proc/acpi/button/lid/*/state` |
| 事件處理程式 | ACPID |
| 遠端存取 | GNOME Remote Desktop (RDP) |

本專案是在上述硬體及軟體環境中開發與測試。

其他 MacBook 機型或 Linux 發行版，只要提供相容的 ACPI 螢幕狀態及背光介面，理論上也可能適用，但目前尚未經過驗證。

## 運作原理

本方案使用 ACPID 偵測螢幕開闔事件，再透過 Shell 腳本控制內建螢幕背光。

### 闔上螢幕時

1. 讀取並儲存目前的背光亮度。
2. 等待 1 秒。
3. 再次確認螢幕是否仍處於闔上狀態。
4. 如果仍然闔上，就將背光亮度設定為 `0`。

### 開啟螢幕時

1. 等待 0.3 秒。
2. 再次確認螢幕是否已經開啟。
3. 恢復先前儲存的背光亮度。
4. 刪除暫存的亮度紀錄。

這些延遲與狀態確認機制，是為了減少實際闔蓋過程中，螢幕背光不必要的開關變化。

儲存的亮度暫時放在：

```text
/run/lid-backlight-brightness
```

此檔案位於暫存目錄，系統重新啟動後會自動清除。

## 系統需求

- Debian 13 (Trixie) + GNOME（本專案已測試的環境）。
- `acpid`。
- 可正常讀取的 ACPI 螢幕開闔狀態介面。
- 可寫入的 Linux 背光介面。
- 安裝及設定時需要 Root 權限。

## 安裝方式

### 1. 安裝 ACPID

```bash
sudo apt update
sudo apt install acpid
sudo systemctl enable --now acpid
```

### 2. 確認背光介面

列出系統目前提供的背光裝置：

```bash
ls -l /sys/class/backlight/
```

本專案測試的 MacBook 使用：

```text
/sys/class/backlight/acpi_video0
```

查看目前及最大亮度：

```bash
cat /sys/class/backlight/acpi_video0/brightness
cat /sys/class/backlight/acpi_video0/max_brightness
```

如果你的系統使用不同的背光裝置名稱，請修改 `lid-backlight.sh` 裡的 `BACKLIGHT` 變數。

### 3. 確認 ACPI 螢幕開闔狀態

```bash
cat /proc/acpi/button/lid/*/state
```

正常情況下會顯示：

```text
state: open
```

或：

```text
state: closed
```

### 4. 安裝腳本

先複製專案：

```bash
git clone https://github.com/stJL/debian-gnome-macbookpro11-1-lid-backlight.git
cd debian-gnome-macbookpro11-1-lid-backlight
```

安裝控制腳本：

```bash
sudo install -m 755 lid-backlight.sh /etc/acpi/lid-backlight.sh
```

安裝 ACPID 事件規則：

```bash
sudo install -m 644 lid-backlight.acpi /etc/acpi/events/lid-backlight
```

重新啟動 ACPID：

```bash
sudo systemctl restart acpid
```

### 5. 設定 systemd-logind 忽略闔蓋事件

如果希望闔上螢幕時系統仍然繼續運作，需要建立：

`/etc/systemd/logind.conf.d/ignore-lid.conf`

內容如下：

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

重新啟動系統以套用設定：

```bash
sudo reboot
```

**注意：** 這項設定只負責避免 systemd-logind 因為闔蓋而讓系統進入休眠，並不會自行關閉螢幕背光。背光控制由 ACPID 腳本另外處理。

## 測試方式

完成安裝後：

1. 打開螢幕，記下目前的亮度。
2. 闔上螢幕。
3. 等待約 3–5 秒。
4. 確認內建螢幕背光已經關閉。
5. 使用 SSH 或已設定的遠端桌面服務連線。
6. 重新打開螢幕，確認先前的亮度已恢復。

建議以不同速度重複闔蓋測試數次。

## 故障排除

### 查看螢幕開闔狀態

```bash
cat /proc/acpi/button/lid/*/state
```

### 查看目前背光亮度

```bash
cat /sys/class/backlight/acpi_video0/brightness
```

### 監控 ACPI 事件

```bash
sudo acpi_listen
```

### 查看診斷紀錄

腳本會將執行紀錄寫入：

```text
/run/lid-backlight-debug.log
```

查看紀錄：

```bash
sudo cat /run/lid-backlight-debug.log
```

紀錄存放在 `/run`，因此重新啟動後不會保留。

## 解除安裝

移除 ACPID 事件規則及控制腳本：

```bash
sudo rm -f /etc/acpi/events/lid-backlight
sudo rm -f /etc/acpi/lid-backlight.sh
sudo systemctl restart acpid
```

如果也想恢復預設的闔蓋休眠行為，可以移除 logind 設定：

```bash
sudo rm -f /etc/systemd/logind.conf.d/ignore-lid.conf
sudo reboot
```

## 限制與注意事項

- 本專案已在 MacBookPro11,1、Debian 13 與 GNOME 環境中測試。
- 不同 MacBook 機型可能使用不同的背光裝置名稱。
- 不同系統提供的 ACPI 螢幕開闔狀態介面也可能不同。
- 1 秒闔蓋延遲及 0.3 秒開蓋延遲，是根據上述實機測試得出的設定。
- 本專案不負責安裝或設定 SSH、RDP、網路或其他遠端存取服務。
- 闔蓋時持續運作可能增加筆電內部溫度，請確保機器有足夠的散熱空間。

## 致謝

本專案由 Repository 維護者在自己的實體硬體上實作及測試。

**OpenAI 的 ChatGPT** 在整個過程中協助了技術問題排查、Shell 腳本開發、除錯、文件撰寫及專案整理。

最終實作及實機測試由 Repository 維護者親自完成，並在 AI 的協助下完成文件整理。

## 授權

本專案採用 MIT License，詳細內容請參閱 [LICENSE](LICENSE)。
