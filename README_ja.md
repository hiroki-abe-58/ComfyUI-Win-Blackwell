# ComfyUI for GeForce RTX 50 シリーズ (Blackwell)

**NVIDIA GeForce RTX 5090/5080/5070 (Blackwell アーキテクチャ, sm_120) + CUDA 13.0 で動作する、世界初の完全ドキュメント化されたWindowsネイティブ ComfyUI セットアップ。**

> **他の言語:** [English](README.md) | [中文](README_zh.md) | [한국어](README_ko.md)

---

## このリポジトリの特徴

RTX 50シリーズ GPU (Blackwell, Compute Capability sm_120) は、2026年初頭時点で **PyTorch安定版に対応していません**。これらのGPUでComfyUIを動作させるには、特定のバージョンと回避策が必要ですが、それらを単一の再現可能なパッケージとしてまとめたものは他にありません。

### 技術的ハイライト

| 項目 | 詳細 |
|------|------|
| **GPUアーキテクチャ** | NVIDIA Blackwell (sm_120) -- RTX 5090 / 5080 / 5070 |
| **CUDAバージョン** | 13.0 (cu130) -- 最新のCUDAランタイム |
| **PyTorch** | Nightly cu130ビルド (stable版ではなく、cu128でもない) |
| **Python** | 3.13 (最新) |
| **Triton** | triton-windows フォーク (公式Tritonはlinux専用) |
| **xformers** | 意図的に除外 (PyTorchのダウングレードを引き起こすため) |
| **カスタムノード** | 動画・音楽生成を含む28個の検証済みノード |
| **プラットフォーム** | Windowsネイティブ (WSL2/Docker不要) |

### ユニークポイント

1. **Blackwell + Windowsネイティブ + CUDA 13.0** -- WSL2やDockerを使わずにBlackwell GPUでComfyUIを完全動作させる、世界でも最も早期に文書化されたセットアップの一つです。

2. **xformers不要アーキテクチャ** -- Blackwell nightly ビルドと非互換なxformersの代わりに、`triton-windows` + `torch.compile` を使用する新しいパラダイムを開拓しています。

3. **28個のカスタムノード検証済み** -- 最先端の動画生成 (Wan 2.1, LTX-Video, HunyuanVideo 1.5, Kandinsky 5.0, LongCat-Video) と音楽生成 (ACE-Step, HeartMuLa) を含む全ノードがRTX 5090 (32GB VRAM) で個別にテスト済みです。

4. **5種類のI2V (Image-to-Video) パイプライン検証済み** -- Blackwellハードウェア上での完全な動画生成ワークフロー検証。

5. **Windows固有の問題と解決策を体系化** -- パス区切り問題、SageAttentionのSDPAフォールバック、Tritonコンパイル回避策など。

---

## 検証済み環境

| コンポーネント | バージョン |
|--------------|----------|
| OS | Windows 11 Pro (Build 26200) |
| GPU | NVIDIA GeForce RTX 5090 (32GB VRAM) |
| CPU | Intel Core Ultra 9 285K (Arrow Lake) |
| RAM | 64GB DDR5-5600 |
| NVIDIAドライバ | 591.55 |
| CUDA | 13.0 |
| Python | 3.13 |
| PyTorch | 2.9.1+cu130 |
| triton-windows | 3.6.0 |

---

## クイックスタート

### 必要なもの

- **Windows 10/11** (64ビット)
- **NVIDIA GeForce RTX 5090 / 5080 / 5070** (またはBlackwell GPU)
- **NVIDIAドライバ 580以上** ([ダウンロード](https://www.nvidia.com/drivers))
- **Git** ([ダウンロード](https://git-scm.com/))
- **7-Zip** ([ダウンロード](https://7-zip.org/)) ポータブル版の解凍用

### ワンクリックセットアップ (初心者の方におすすめ)

```
1. このリポジトリをダウンロードまたはクローン
2. setup.bat をダブルクリック
3. インストール完了まで待つ (約20分)
4. run.bat をダブルクリックしてComfyUIを起動
5. ブラウザで http://localhost:8188 を開く
```

### 手動セットアップ

```powershell
# リポジトリをクローン
git clone https://github.com/hiroki-abe-58/ComfyUI-GeForce-Blackwell.git
cd ComfyUI-GeForce-Blackwell

# セットアップスクリプトを実行
powershell -ExecutionPolicy Bypass -File setup.ps1

# ComfyUIを起動
.\run.bat
```

### 環境の確認

```powershell
# セットアップ後、すべてが正しく動作しているか確認
python verify_env.py
```

---

## Blackwell + Windowsの5つの鉄則

以下のルールは**必ず**守ってください。違反すると環境が壊れます。

| # | 鉄則 | 理由 | 違反時の症状 |
|---|------|------|------------|
| 1 | **PyTorch nightly cu130を使う** | stable版はsm_120カーネル未搭載 | `RuntimeError: sm_120 is not compatible` |
| 2 | **xformersを絶対にインストールしない** | PyTorchをstable版に強制ダウングレードする | すべてが動かなくなる |
| 3 | **requirements.txtからtorchを除外する** | pipがnightlyをstableで上書きする | サイレントなバージョンダウングレード |
| 4 | **カスタムノード追加後は必ず確認** | ノードの依存関係がstable torchを要求する場合がある | 動いていたものが動かなくなる |
| 5 | **プロキシ環境変数をクリアする** | システムプロキシがpip/git接続をブロックする | インストール失敗 |

---

## 検証済みカスタムノード (28個)

### 動画生成
- ComfyUI-WanVideoWrapper -- Wan 2.1 動画生成
- ComfyUI-LTXVideo -- LTX-Video 生成
- comfyui-videohelpersuite -- 動画結合・ヘルパー
- comfyui_longcat_image -- LongCat 動画処理

### 音声・音楽生成
- ComfyUI-AceMusic -- ACE-Step 音楽生成
- ComfyUI-HeartMuLa -- HeartMuLa 音楽生成
- ComfyUI-MelBandRoFormer -- 音声分離
- ComfyUI_FL-HeartMuLa -- HeartMuLa FL バリアント

### 画像処理・編集
- ComfyUI-Step1X-Edit -- Step1X 画像編集
- comfyui-impact-pack -- 検出・インペインティング
- comfyui_controlnet_aux -- ControlNet プリプロセッサ
- comfyui_layerstyle -- レイヤー合成
- comfyui-depthanythingv2 -- 深度推定

### ユーティリティ・管理
- ComfyUI-Manager -- ノード管理
- その他14個のユーティリティノード

---

## 検証済みI2V (Image-to-Video) ワークフロー

| モデル | パラメータ数 | FP8サイズ | 32GB VRAMでの動作 |
|--------|------------|----------|-----------------|
| HunyuanVideo 1.5 I2V | 8.3B | ~16GB | 快適 -- おすすめ |
| Kandinsky 5.0 Lite I2V | 2B | ~4GB | 非常に快適 |
| LTX-2 I2V | 19B | ~25GB | FP8で動作可能 |
| LongCat-Video TI2V | 13.6B | ~14.5GB | 調整すれば動作可能 |
| Kandinsky 5.0 Pro I2V | 19B | ~40GB | CPU offload必須、低速 |

---

## Windows固有のトラブルシューティング

### モデルパスエラー (`Value not in list`)

Linux向けワークフローはモデルパスにスラッシュ (`/`) を使用しています。Windowsではバックスラッシュ (`\`) が必要です。

**自動修正:**
```powershell
python scripts/fix_windows_compat.py your_workflow.json
```

### SageAttentionが使えない

SageAttentionはWindowsでのビルドが困難です。代わりにSDPA (PyTorch標準) を使用してください:
- ワークフロー内の `attention_mode` を `sageattn` から `sdpa` に変更
- または `fix_windows_compat.py` で自動修正

### PyTorchが知らないうちにダウングレードされた

パッケージインストール後は必ず確認:
```powershell
python -c "import torch; print(torch.__version__)"
```
`cu130` が含まれていなければ再インストール:
```powershell
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu130
```

---

## 更新方法

`update.bat` をダブルクリック、または:
```powershell
powershell -ExecutionPolicy Bypass -File update.ps1
```

---

## FAQ

**Q: WSL2やDockerは必要ですか?**
A: いいえ。このセットアップはWindowsネイティブで完全に動作します。

**Q: xformersは使えますか?**
A: いいえ。xformersはPyTorch stable版への強制ダウングレードを引き起こし、sm_120非対応になります。代わりにtriton-windows + torch.compileを使用してください。

**Q: RTX 4090 (Ada Lovelace) でも動きますか?**
A: はい。cu130は後方互換性があります。ただしRTX 4090ユーザーはstable版PyTorchも使用可能です。

**Q: モデルはどこに置けばいいですか?**
A: セットアップ後、`ComfyUI_windows_portable/ComfyUI/models/` にモデルを配置してください。共有モデルストレージについては `configs/extra_model_paths.yaml.example` を参照してください。

---

## コントリビューション

プルリクエストを歓迎します。Blackwellハードウェアで追加のカスタムノードやワークフローを検証された場合、`custom-nodes.json` の更新PRをお送りください。

---

## ライセンス

MIT License -- [LICENSE](LICENSE) を参照

---

## 謝辞

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by Comfy-Org
- [triton-windows](https://github.com/woct0rdho/triton-windows) by woct0rdho
- [PyTorch](https://pytorch.org/) nightly チーム (sm_120サポート)
- `custom-nodes.json` に記載の全カスタムノード開発者の皆様
