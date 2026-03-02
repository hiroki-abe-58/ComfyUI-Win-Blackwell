# ComfyUI -- GeForce RTX 50 시리즈 (Blackwell) 지원

**NVIDIA GeForce RTX 5090/5080/5070 (Blackwell 아키텍처, sm_120) + CUDA 13.0을 위한, 세계 최초로 완전히 문서화된 Windows 네이티브 ComfyUI 설정.**

> **다른 언어:** [English](README.md) | [日本語](README_ja.md) | [中文](README_zh.md)

---

## 이 저장소의 특징

RTX 50 시리즈 GPU (Blackwell, Compute Capability sm_120)는 2026년 초 기준으로 **PyTorch 안정 버전에서 지원되지 않습니다**. 이러한 GPU에서 ComfyUI를 실행하려면 특정 버전과 해결 방법이 필요하며, 이를 단일 재현 가능한 패키지로 정리한 것은 이 프로젝트가 처음입니다.

### 기술적 하이라이트

| 항목 | 세부사항 |
|------|---------|
| **GPU 아키텍처** | NVIDIA Blackwell (sm_120) -- RTX 5090 / 5080 / 5070 |
| **CUDA 버전** | 13.0 (cu130) -- 최신 CUDA 런타임 |
| **PyTorch** | Nightly cu130 빌드 (안정 버전 아님, cu128 아님) |
| **Python** | 3.13 (최신) |
| **Triton** | triton-windows 포크 (공식 Triton은 Linux 전용) |
| **xformers** | 의도적 제외 (PyTorch 다운그레이드 유발) |
| **커스텀 노드** | 동영상 및 음악 생성을 포함한 28개 검증 노드 |
| **플랫폼** | Windows 네이티브 (WSL2/Docker 불필요) |

### 고유한 특징

1. **Blackwell + Windows 네이티브 + CUDA 13.0** -- WSL2나 Docker 없이 Blackwell GPU에서 ComfyUI를 완전히 실행하는, 세계에서 가장 이른 시기에 문서화된 설정 중 하나입니다.

2. **xformers 불필요 아키텍처** -- Blackwell nightly 빌드와 호환되지 않는 xformers 대신 `triton-windows` + `torch.compile`을 사용하는 새로운 패러다임을 개척합니다.

3. **28개 커스텀 노드 검증 완료** -- 최첨단 동영상 생성 (Wan 2.1, LTX-Video, HunyuanVideo 1.5, Kandinsky 5.0, LongCat-Video) 및 음악 생성 (ACE-Step, HeartMuLa)을 포함한 모든 노드가 RTX 5090 (32GB VRAM)에서 개별 테스트되었습니다.

4. **5종 이미지-투-비디오 파이프라인 검증 완료** -- Blackwell 하드웨어에서의 완전한 I2V 워크플로 검증.

5. **Windows 특화 문제 및 해결책 체계화** -- 경로 구분자 문제, SageAttention의 SDPA 대체, Triton 컴파일 우회 방안 등.

---

## 검증된 환경

| 구성요소 | 버전 |
|---------|------|
| OS | Windows 11 Pro (Build 26200) |
| GPU | NVIDIA GeForce RTX 5090 (32GB VRAM) |
| CPU | Intel Core Ultra 9 285K (Arrow Lake) |
| RAM | 64GB DDR5-5600 |
| NVIDIA 드라이버 | 591.55 |
| CUDA | 13.0 |
| Python | 3.13 |
| PyTorch | 2.9.1+cu130 |
| triton-windows | 3.6.0 |

---

## 빠른 시작

### 사전 요구사항

- **Windows 10/11** (64비트)
- **NVIDIA GeForce RTX 5090 / 5080 / 5070** (또는 Blackwell GPU)
- **NVIDIA 드라이버 580+** ([다운로드](https://www.nvidia.com/drivers))
- **Git** ([다운로드](https://git-scm.com/))
- **7-Zip** ([다운로드](https://7-zip.org/)) 포터블 버전 압축 해제용

### 원클릭 설정 (초보자 권장)

```
1. 이 저장소를 다운로드하거나 클론
2. setup.bat 더블클릭
3. 설치 완료까지 대기 (약 20분)
4. run.bat 더블클릭으로 ComfyUI 시작
5. 브라우저에서 http://localhost:8188 열기
```

### 수동 설정

```powershell
# 저장소 클론
git clone https://github.com/hiroki-abe-58/ComfyUI-GeForce-Blackwell.git
cd ComfyUI-GeForce-Blackwell

# 설정 스크립트 실행
powershell -ExecutionPolicy Bypass -File setup.ps1

# ComfyUI 시작
.\run.bat
```

### 환경 검증

```powershell
# 설정 후, 모든 것이 정상인지 확인
python verify_env.py
```

---

## Blackwell + Windows 5대 철칙

아래 규칙은 **반드시** 지켜야 합니다. 위반하면 환경이 손상됩니다.

| # | 철칙 | 이유 | 위반 시 증상 |
|---|------|------|------------|
| 1 | **PyTorch nightly cu130 사용** | 안정 버전에 sm_120 커널 미포함 | `RuntimeError: sm_120 is not compatible` |
| 2 | **xformers 절대 설치 금지** | PyTorch를 안정 버전으로 강제 다운그레이드 | 모든 것이 작동 중지 |
| 3 | **requirements.txt에서 torch 제외** | pip이 nightly를 안정 버전으로 덮어씀 | 무음 버전 다운그레이드 |
| 4 | **커스텀 노드 추가 후 반드시 확인** | 노드 의존성이 안정 버전 torch를 요구할 수 있음 | 이전에 작동하던 것이 고장 |
| 5 | **프록시 환경변수 초기화** | 시스템 프록시가 pip/git 연결 차단 | 설치 실패 |

---

## 검증된 커스텀 노드 (28개)

### 동영상 생성
- ComfyUI-WanVideoWrapper -- Wan 2.1 동영상 생성
- ComfyUI-LTXVideo -- LTX-Video 생성
- comfyui-videohelpersuite -- 동영상 결합 및 도우미
- comfyui_longcat_image -- LongCat 동영상 처리

### 오디오/음악 생성
- ComfyUI-AceMusic -- ACE-Step 음악 생성
- ComfyUI-HeartMuLa -- HeartMuLa 음악 생성
- ComfyUI-MelBandRoFormer -- 오디오 소스 분리
- ComfyUI_FL-HeartMuLa -- HeartMuLa FL 변형

### 이미지 처리 및 편집
- ComfyUI-Step1X-Edit -- Step1X 이미지 편집
- comfyui-impact-pack -- 감지 및 인페인팅
- comfyui_controlnet_aux -- ControlNet 전처리기
- comfyui_layerstyle -- 레이어 합성
- comfyui-depthanythingv2 -- 깊이 추정

### 유틸리티 및 관리
- ComfyUI-Manager -- 노드 관리
- 기타 14개 유틸리티 노드

---

## 검증된 이미지-투-비디오 워크플로

| 모델 | 파라미터 수 | FP8 크기 | 32GB VRAM 성능 |
|------|-----------|---------|---------------|
| HunyuanVideo 1.5 I2V | 8.3B | ~16GB | 원활 -- 추천 |
| Kandinsky 5.0 Lite I2V | 2B | ~4GB | 매우 원활 |
| LTX-2 I2V | 19B | ~25GB | FP8로 실행 가능 |
| LongCat-Video TI2V | 13.6B | ~14.5GB | 조정 후 실행 가능 |
| Kandinsky 5.0 Pro I2V | 19B | ~40GB | CPU 오프로드 필요, 느림 |

---

## Windows 특화 트러블슈팅

### 모델 경로 오류 (`Value not in list`)

Linux 워크플로는 모델 경로에 슬래시 (`/`)를 사용합니다. Windows에서는 백슬래시 (`\`)가 필요합니다.

**자동 수정:**
```powershell
python scripts/fix_windows_compat.py your_workflow.json
```

### SageAttention 사용 불가

SageAttention은 Windows에서 빌드가 어렵습니다. 대신 SDPA (PyTorch 내장)를 사용하세요:
- 워크플로의 `attention_mode`를 `sageattn`에서 `sdpa`로 변경
- 또는 `fix_windows_compat.py`로 자동 수정

### PyTorch가 자동 다운그레이드됨

패키지 설치 후 반드시 확인:
```powershell
python -c "import torch; print(torch.__version__)"
```
`cu130`이 포함되지 않으면 재설치:
```powershell
pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu130
```

---

## 업데이트 방법

`update.bat` 더블클릭 또는:
```powershell
powershell -ExecutionPolicy Bypass -File update.ps1
```

---

## FAQ

**Q: WSL2나 Docker가 필요한가요?**
A: 아니요. 이 설정은 Windows 네이티브에서 완전히 실행됩니다.

**Q: xformers를 사용할 수 있나요?**
A: 아니요. xformers는 PyTorch를 안정 버전으로 강제 다운그레이드하며, 해당 버전은 sm_120을 지원하지 않습니다.

**Q: RTX 4090에서도 사용할 수 있나요?**
A: 네. cu130은 하위 호환됩니다. 다만 RTX 4090 사용자는 PyTorch 안정 버전도 사용 가능합니다.

**Q: 모델은 어디에 넣나요?**
A: 설정 완료 후 `ComfyUI_windows_portable/ComfyUI/models/`에 모델을 배치하세요. 공유 모델 저장소는 `configs/extra_model_paths.yaml.example`을 참조하세요.

---

## 기여

Pull Request를 환영합니다. Blackwell 하드웨어에서 추가 커스텀 노드나 워크플로를 검증하셨다면 `custom-nodes.json` 업데이트 PR을 보내주세요.

---

## 라이선스

MIT License -- [LICENSE](LICENSE) 참조

---

## 감사의 말

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI) by Comfy-Org
- [triton-windows](https://github.com/woct0rdho/triton-windows) by woct0rdho
- [PyTorch](https://pytorch.org/) nightly 팀 (sm_120 지원)
- `custom-nodes.json`에 기재된 모든 커스텀 노드 개발자 여러분
