echo "worker-comfyui: Starting ComfyUI"
comfy launch -- --listen 0.0.0.0 --port 8188 &

echo "worker-comfyui: Starting RunPod Handler"
python -u /root/rp_handler.py