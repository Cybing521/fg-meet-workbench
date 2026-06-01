# COMSOL validation workflow video

This folder contains a captioned workflow video for explaining the remaining COMSOL validation tasks.

## Files

- `comsol_validation_workflow.mp4`: 63-second silent 1080p video with Chinese captions.
- `narration.md`: optional narration script for voice-over or PPT notes.
- `slides/`: source slide images used to build the video.
- `slides.txt`: ffmpeg concat list used by the build script.

## Build command

```powershell
python tools\build_comsol_validation_video.py
```

## Record a real COMSOL GUI operation

Open COMSOL and keep the model window visible, then run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\record_comsol_gui_video.ps1 -DurationSec 900 -Name porous_U_Vf05_e20_Even_CFFF
```

The GUI recording is written to `reports/2026-06-01-comsol-validation-video/gui-recordings/`. That directory is ignored by git because it captures the local desktop and may contain private screen content.
