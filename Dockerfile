# 使用包含CUDA 12.2的NVIDIA基础镜像
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ="Etc/UTC"

ENV COMFYUI_PATH=/root/comfy/ComfyUI

ARG HF_TOKEN

RUN apt-get install -y curl

RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash

RUN apt-get update

RUN apt-get install -y \
    git \
    ffmpeg \
    wget \
    git-lfs

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# 安装核心Python依赖
RUN pip install \
    fastapi[standard]==0.115.4 \
    comfy-cli \
    opencv-python \
    imageio-ffmpeg \
    hf_transfer \
    scikit-image \
    huggingface_hub[hf_transfer]==0.26.2 \
    runpod

# 安装ComfyUI核心
RUN comfy --skip-prompt install --nvidia

## 安装所有第三方节点和依赖
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager $COMFYUI_PATH/custom_nodes/comfyui-manager
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use $COMFYUI_PATH/custom_nodes/ComfyUI-Easy-Use && \
    pip install -r $COMFYUI_PATH/custom_nodes/ComfyUI-Easy-Use/requirements.txt
RUN git clone https://github.com/kijai/ComfyUI-Florence2.git $COMFYUI_PATH/custom_nodes/ComfyUI-Florence2 && \
    pip install -r $COMFYUI_PATH/custom_nodes/ComfyUI-Florence2/requirements.txt
RUN git clone https://github.com/storyicon/comfyui_segment_anything.git $COMFYUI_PATH/custom_nodes/comfyui_segment_anything && \
    pip install -r $COMFYUI_PATH/custom_nodes/comfyui_segment_anything/requirements.txt
RUN git clone https://github.com/kaibioinfo/ComfyUI_AdvancedRefluxControl.git $COMFYUI_PATH/custom_nodes/ComfyUI_AdvancedRefluxControl
RUN git clone https://github.com/lrzjason/Comfyui-In-Context-Lora-Utils.git $COMFYUI_PATH/custom_nodes/Comfyui-In-Context-Lora-Utils
RUN git clone https://github.com/cubiq/ComfyUI_essentials.git $COMFYUI_PATH/custom_nodes/ComfyUI_essentials && \
    pip install -r $COMFYUI_PATH/custom_nodes/ComfyUI_essentials/requirements.txt

# Log in to Hugging Face CLI using the build argument token
# Only run login if HF_TOKEN is provided
RUN huggingface-cli login --token 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

RUN mkdir -p $COMFYUI_PATH/models/LLM \
             $COMFYUI_PATH/models/clip \
             $COMFYUI_PATH/models/grounding-dino \
             $COMFYUI_PATH/models/rembg \
             $COMFYUI_PATH/models/style_models \
             $COMFYUI_PATH/models/vae \
#             $COMFYUI_PATH/models/bert-base-uncased \
             $COMFYUI_PATH/models/clip_vision \
             $COMFYUI_PATH/models/loras \
             $COMFYUI_PATH/models/sams \
             $COMFYUI_PATH/models/unet

# Download specific models identified from the workflow using huggingface-cli
RUN huggingface-cli download black-forest-labs/FLUX.1-Redux-dev flux1-redux-dev.safetensors --local-dir $COMFYUI_PATH/models/style_models/ --local-dir-use-symlinks False

RUN huggingface-cli download Comfy-Org/sigclip_vision_384 sigclip_vision_patch14_384.safetensors --local-dir $COMFYUI_PATH/models/clip_vision/ --local-dir-use-symlinks False

RUN huggingface-cli download theunlikely/catvton-flux-lora-beta catvton-flux-lora-beta-rank128.safetensors --local-dir $COMFYUI_PATH/models/loras/ --local-dir-use-symlinks False

RUN huggingface-cli download zer0int/CLIP-GmP-ViT-L-14 ViT-L-14-TEXT-detail-improved-hiT-GmP-HF.safetensors --local-dir $COMFYUI_PATH/models/clip/ --local-dir-use-symlinks False

# VAE (User confirmed source: black-forest-labs/FLUX.1-Fill-dev)
RUN huggingface-cli download black-forest-labs/FLUX.1-Fill-dev ae.safetensors --local-dir $COMFYUI_PATH/models/vae/ --local-dir-use-symlinks False

# Main Flux UNET Model
RUN huggingface-cli download black-forest-labs/FLUX.1-Fill-dev flux1-fill-dev.safetensors --local-dir $COMFYUI_PATH/models/unet/ --local-dir-use-symlinks False

# Second CLIP Text Encoder (T5)
RUN huggingface-cli download comfyanonymous/flux_text_encoders t5xxl_fp16.safetensors --local-dir $COMFYUI_PATH/models/clip/ --local-dir-use-symlinks False

RUN huggingface-cli download briaai/RMBG-1.4 model.pth --local-dir $COMFYUI_PATH/models/rembg/ --local-dir-use-symlinks False
RUN mv $COMFYUI_PATH/models/rembg/model.pth $COMFYUI_PATH/models/rembg/RMBG-1.4.pth

# https://github.com/storyicon/comfyui_segment_anything
RUN wget -q -O $COMFYUI_PATH/models/sams/sam_vit_b_01ec64.pth https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth
RUN huggingface-cli download ShilongLiu/GroundingDINO groundingdino_swinb_cogcoor.pth --local-dir $COMFYUI_PATH/models/grounding-dino/ --local-dir-use-symlinks False
RUN huggingface-cli download ShilongLiu/GroundingDINO GroundingDINO_SwinB.cfg.py --local-dir $COMFYUI_PATH/models/grounding-dino/ --local-dir-use-symlinks False

# Make sure git-lfs is installed (https://git-lfs.com)
RUN git lfs install
RUN git clone https://huggingface.co/google-bert/bert-base-uncased $COMFYUI_PATH/models/bert-base-uncased
RUN git clone https://huggingface.co/microsoft/Florence-2-base $COMFYUI_PATH/models/LLM/Florence-2-base

# 复制本地自定义节点和模型
COPY src/start.sh /root/
COPY src/rp_handler.py /root/

RUN chmod +x /root/start.sh

# 暴露端口并设置启动命令
EXPOSE 8188
CMD ["/root/start.sh"]