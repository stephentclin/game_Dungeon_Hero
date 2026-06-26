# Goblin Commander: Flip the Script

Godot 4.7 / GDScript 製作的 2D 俯視角動作 + Match Board 混合遊戲。玩家不是勇者，而是哥布林指揮官：左側戰場自動戰鬥，右側 Match Board 透過方塊與消除規則召喚怪物，目標是徹底擊敗不斷復活、逐漸變強的勇者。

---

## 目前版本重點

- 預設介面為英文，玩家仍可在 Settings 中切換中文。
- 主畫面按 START 後會先顯示 `Introduction.png` 初學者說明。
- 按 NEXT 後進入遊戲，第一次進入遊戲會顯示 Match Board Guide。
- 關閉 Guide 後開始 `3, 2, 1, GO` 倒數，倒數結束才正式開始遊玩。
- 遊玩中可按 `H` 再次開啟 / 關閉 Match Board Guide。
- 後續進入新房間時不再自動顯示 Guide，會直接倒數開始。
- Match Board 方塊會從上方隨機欄位生成，不再固定從中間掉落。
- Match Board 任一欄觸頂時，判定勇者清關並進入下一關流程。
- 沒有小怪時，英雄會在地圖內巡邏，不會在中心點抖動。
- HP 標題列左側顯示愛心命數，房間資訊保持置中，已移除 `HERO LV` 顯示。
- Skill Tree 頁面加入 `skill_tree_sound.mp3` 音效，並補完整英文翻譯。
- 英雄復活時加入 4 幀像素風復活特效。
- 最終結局加入影片與音效播放，並修正遊戲結束後仍能繼續操作的問題。

---

## 遊戲流程

1. 開啟主選單。
2. 按下 **START**。
3. 顯示 **Beginner Guide / Introduction**。
4. 按下 **NEXT**。
5. 進入遊戲並顯示 **Match Board Guide**。
6. 按下 **Close**。
7. 播放 `3 → 2 → 1 → GO` 倒數。
8. 正式開始：左側英雄自動戰鬥，右側玩家操作 Match Board。
9. 清除 Match Board 方塊會召喚怪物到左側戰場。
10. 擊敗勇者、觸發復活、選擇 Power Item，繼續挑戰下一階段。
11. 最終擊殺勇者或指揮官被擊殺後，播放對應結局影片與音效。

---

## 操作方式

### 主選單與系統

| 操作 | 功能 |
|---|---|
| START | 開始遊戲並進入 Introduction |
| Settings | 調整語言與遊戲設定 |
| H | 遊玩中開啟 / 關閉 Match Board Guide |
| 滑鼠左鍵 | 點擊 UI、選擇獎勵、操作按鈕 |

### Match Board

| 操作 | 功能 |
|---|---|
| `←` / `→` 或 `A` / `D` | 移動掉落方塊 |
| `↑` 或 `W` | 旋轉方塊 |
| `↓` 或 `S` | 快速下降 |
| `Space` / `Enter` | Hard Drop |
| 滑鼠拖曳 / 點擊相鄰方塊 | 交換方塊 |
| 點擊特殊方塊 | 引爆 / 清除特殊方塊 |

---

## Match Board 規則

- 掉落方塊類似 Tetris，但與 Candy Crush 風格的 Match-3 消除結合。
- 方塊落下後，可以透過交換相鄰方塊製造消除。
- 3 個或以上相同 icon 連成一列或一欄即可清除。
- 清除結果會召喚不同怪物到左側戰場。
- 任一欄方塊觸頂時，代表勇者清關並進入下一關流程。

### 召喚規則

| 條件 | 召喚 |
|---|---|
| Match 3 | Skeleton Warrior |
| Match 4 | Goblin Archer |
| Match 5 | Bomber Imp |
| L Shape | Slime Guard |
| T Shape | Voodoo Shaman |
| Cross Shape | Ogre |

優先順序：`Cross > T > L > 5 > 4 > 3`

---

## 左側戰場規則

- 左側戰場為自動戰鬥。
- 玩家只控制右側 Match Board，不直接控制英雄或怪物。
- 英雄會自動巡邏、追擊、攻擊怪物。
- 沒有怪物時，英雄會在安全區域巡邏。
- 怪物會自動攻擊英雄。
- 英雄死亡但仍有命數時，會進入復活與 Power Item 流程。
- 英雄復活時會播放像素魔法陣復活特效。

---

## 生命、房間與結局

- HP 標題列左側顯示愛心命數。
- 房間名稱、INK、WARNING 等資訊置中顯示。
- 勇者在不同房間會逐漸變強。
- 遊戲結束後會鎖住 Match Board、放怪、熱鍵、獎勵與召喚邏輯。
- 只有重新開始新遊戲才會解除結局鎖定。

### 最終影片與音效

| 結局 | 影片 | 音效 |
|---|---|---|
| 英雄成功擊殺 commander | `res://assets/videos/fail.mp4` | `res://assets/audio/Wilhelm Scream.ogg` |
| 英雄最終被擊殺 | `res://assets/videos/success.mp4` | `res://assets/audio/Tom Screaming.ogg` |

---

## 主要素材路徑

| 類型 | 路徑 |
|---|---|
| Introduction 圖 | `res://assets/ui/Introduction.png` |
| Match Board Guide | 由 `PuzzleBoard.gd` 動態建立 |
| 主畫面音樂 | `res://assets/audio/Crusade.mp3` |
| Skill Tree 音效 | `res://assets/audio/skill_tree_sound.mp3` |
| 英雄復活特效 | `res://assets/effects/hero_revive_effect_4f.png` |
| 失敗影片 | `res://assets/videos/fail.mp4` |
| 勝利影片 | `res://assets/videos/success.mp4` |

---

## 主要程式檔案

| 檔案 | 用途 |
|---|---|
| `scenes/Main.tscn` | 主要遊戲場景 |
| `scenes/MainMenu.tscn` | 主選單場景 |
| `scripts/Main.gd` | 遊戲主流程、房間、結局、獎勵流程 |
| `scripts/UIController.gd` | UI、語言、結算、Skill Tree、彈窗流程 |
| `scripts/PuzzleBoard.gd` | Match Board、Guide、倒數、掉落方塊、輸入鎖定 |
| `scripts/Hero.gd` | 英雄 AI、巡邏、戰鬥、復活邏輯 |
| `scripts/Monster.gd` | 怪物 AI、攻擊與特殊能力 |
| `scripts/PlacementSystem.gd` | 召喚與放置系統 |
| `scripts/SaveSystem.gd` | 存檔、語言、永久進度 |
| `scripts/data/BalanceConfig.gd` | 數值平衡設定 |

---

## 如何執行

1. 安裝 **Godot 4.7 stable** 或相容的 Godot 4.x 版本。
2. 解壓縮本專案。
3. 使用 Godot 開啟 `project.godot`。
4. 執行主場景。

命令列範例：

```bash
godot --path .
```

---

## 測試清單

建議每次修改後確認以下項目：

- 主選單預設為英文。
- START 後先顯示 Introduction。
- NEXT 後進入遊戲並顯示 Match Board Guide。
- Close 後才開始 `3, 2, 1, GO`。
- 遊玩中按 `H` 可重新開啟 Guide。
- 後續房間不再自動顯示 Guide，直接倒數。
- Match Board 掉落方塊生成位置為隨機欄位。
- Match Board 觸頂會進入下一關流程。
- 沒有小怪時英雄會巡邏，不會抖動。
- Skill Tree 進入時會播放音效，英文翻譯正常。
- 英雄復活時會播放復活特效。
- 最終勝利 / 失敗影片與音效正常播放。
- 遊戲結束後不能透過關閉結算 UI 繼續遊玩。

---

## 最新整合紀錄

本 README 已整理並合併過去分散的版本 README，保留目前版本需要的玩法、操作、素材路徑、主要檔案與驗收重點。舊版零散 README 已移除，避免專案根目錄過多重複文件。
