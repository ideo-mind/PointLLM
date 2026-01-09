set shell := ["sh", "-c"]
set windows-shell := ["powershell.exe", "-NoLogo", "-Command"]
set dotenv-filename := ".env"
set export

# Default model path
model_name := "RunsenXu/PointLLM_7B_v1.2"
# Default data path
data_path := "data/objaverse_data"

# Install dependencies using uv
setup:
    uv sync --all-extras

# Helper to run python scripts with pythonpath set
_run script *args:
    uv run python {{script}} {{args}}

# Start the CLI chat
chat-cli *opts:
    uv run pointllm/eval/PointLLM_chat.py --model_name {{model_name}} --data_name {{data_path}} --torch_dtype float32 {{opts}}

# Start the Gradio web UI
chat-gradio *opts:
    uv run pointllm/eval/chat_gradio.py --model_name {{model_name}} --data_path {{data_path}} {{opts}}

# Run specific evaluation scripts
eval task *opts:
    #!/usr/bin/env bash
    if [ "{{task}}" == "objaverse" ]; then
         uv run pointllm/eval/eval_objaverse.py --model_name {{model_name}} {{opts}}
    elif [ "{{task}}" == "modelnet" ]; then
         uv run pointllm/eval/eval_modelnet_cls.py --model_name {{model_name}} {{opts}}
    else
        echo "Unknown task: {{task}}. Available: objaverse, modelnet"
        exit 1
    fi

import? "local.justfile"

RANDOM := env("RANDOM", "42")

# Download and prepare Objaverse data
download-data download_dir="downloads":
    #!/usr/bin/env bash
    echo "Creating download directory: {{download_dir}}"
    mkdir -p {{download_dir}}
    
    cd {{download_dir}}
    
    if [ ! -f "Objaverse_660K_8192_npy.tar.gz" ]; then
        if [ ! -f "Objaverse_660K_8192_npy_split_aa" ]; then
            echo "Downloading split aa..."
            curl -L -O https://huggingface.co/datasets/RunsenXu/PointLLM/resolve/main/Objaverse_660K_8192_npy_split_aa
        fi
        
        if [ ! -f "Objaverse_660K_8192_npy_split_ab" ]; then
            echo "Downloading split ab..."
            curl -L -O https://huggingface.co/datasets/RunsenXu/PointLLM/resolve/main/Objaverse_660K_8192_npy_split_ab
        fi
        
        echo "Merging files..."
        cat Objaverse_660K_8192_npy_split_a* > Objaverse_660K_8192_npy.tar.gz
    else
        echo "Merged archive already exists, skipping download/merge."
    fi
    
    echo "Extracting..."
    if [ ! -d "8192_npy" ]; then
        tar -xvf Objaverse_660K_8192_npy.tar.gz
    else
        echo "Directory 8192_npy already exists, skipping extraction."
    fi
    
    cd ..
    
    echo "Setting up data link..."
    mkdir -p data
    if [ ! -L "data/objaverse_data" ]; then
        ln -s "$(pwd)/{{download_dir}}/8192_npy" data/objaverse_data
        echo "Link created at data/objaverse_data"
    else
        echo "Link data/objaverse_data already exists."
    fi



