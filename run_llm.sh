#!/bin/bash

python generate.py \
    --share=True \
    --gradio_offline_level=1 \
    --base_model=h2oai/h2ogpt-gm-oasst1-en-2048-falcon-7b-v3 \
    --score_model=None \
    --load_4bit=True \
    --prompt_type=human_bot \
    --user_path='user_path' \
    --allow_upload_to_user_data=True
