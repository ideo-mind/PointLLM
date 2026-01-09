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



