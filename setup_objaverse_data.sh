#!/bin/bash

# PointLLM Objaverse Data Setup Script
# This script automates the download and setup of 660K Objaverse colored point clouds
# Total size: ~77GB

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0;m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PointLLM Objaverse Data Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Configuration
HUGGINGFACE_URL="https://huggingface.co/datasets/RunsenXu/PointLLM/resolve/main"
DOWNLOAD_DIR="${HOME}/objaverse_downloads"
FINAL_DIR="${HOME}/objaverse_data"
POINTLLM_DIR="${HOME}/PointLLM"

# File names
FILE_A="Objaverse_660K_8192_npy_split_aa"
FILE_B="Objaverse_660K_8192_npy_split_ab"
MERGED_FILE="Objaverse_660K_8192_npy.tar.gz"

# Create download directory
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

echo -e "${YELLOW}Download directory: $DOWNLOAD_DIR${NC}"
echo -e "${YELLOW}Final data directory: $FINAL_DIR${NC}"

# Function to download file with progress
download_file() {
    local url=$1
    local filename=$2
    
    if [ -f "$filename" ]; then
        echo -e "${GREEN}✓ $filename already exists, skipping download${NC}"
    else
        echo -e "${YELLOW}Downloading $filename...${NC}"
        wget --continue --progress=bar:force "$url/$filename" -O "$filename" 2>&1 | \
            grep --line-buffered -oP '[0-9]+%|[0-9]+[KMG]' | \
            while read line; do
                echo -ne "\r${YELLOW}Progress: $line${NC}"
            done
        echo
        echo -e "${GREEN}✓ Downloaded $filename${NC}"
    fi
}

# Check available disk space
echo -e "${YELLOW}Checking available disk space...${NC}"
AVAILABLE_SPACE=$(df -BG "$DOWNLOAD_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
REQUIRED_SPACE=100  # 77GB for files + extra for extraction

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo -e "${RED}✗ Insufficient disk space!${NC}"
    echo -e "${RED}Required: ${REQUIRED_SPACE}GB, Available: ${AVAILABLE_SPACE}GB${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Sufficient disk space available: ${AVAILABLE_SPACE}GB${NC}"

# Download files
echo -e "\n${YELLOW}Step 1/4: Downloading compressed files...${NC}"
download_file "$HUGGINGFACE_URL" "$FILE_A"
download_file "$HUGGINGFACE_URL" "$FILE_B"

# Merge files
echo -e "\n${YELLOW}Step 2/4: Merging split files...${NC}"
if [ -f "$MERGED_FILE" ]; then
    echo -e "${GREEN}✓ Merged file already exists, skipping merge${NC}"
else
    cat "${FILE_A}" "${FILE_B}" > "$MERGED_FILE"
    echo -e "${GREEN}✓ Files merged successfully${NC}"
fi

# Extract files
echo -e "\n${YELLOW}Step 3/4: Extracting data (this may take a while)...${NC}"
if [ -d "8192_npy" ]; then
    echo -e "${GREEN}✓ Data already extracted, skipping extraction${NC}"
else
    tar -xzf "$MERGED_FILE" --checkpoint=10000 --checkpoint-action=echo="%T"
    echo -e "${GREEN}✓ Data extracted successfully${NC}"
fi

# Move to final location
if [ ! -d "$FINAL_DIR" ]; then
    mv 8192_npy "$FINAL_DIR"
    echo -e "${GREEN}✓ Data moved to $FINAL_DIR${NC}"
fi

# Setup PointLLM data directory
echo -e "\n${YELLOW}Step 4/4: Setting up PointLLM data links...${NC}"
cd "$POINTLLM_DIR"
mkdir -p data

if [ -L "data/objaverse_data" ] || [ -d "data/objaverse_data" ]; then
    echo -e "${YELLOW}Removing existing link/directory${NC}"
    rm -rf data/objaverse_data
fi

ln -s "$FINAL_DIR" data/objaverse_data
echo -e "${GREEN}✓ Symlink created: data/objaverse_data -> $FINAL_DIR${NC}"

# Verify setup
echo -e "\n${YELLOW}Verifying installation...${NC}"
FILE_COUNT=$(ls "$FINAL_DIR" | wc -l)
echo -e "${GREEN}✓ Found $FILE_COUNT point cloud files${NC}"

# Cleanup option
echo -e "\n${YELLOW}Cleanup: Do you want to remove downloaded archives to save space? (y/N)${NC}"
read -t 10 -n 1 -r CLEANUP || CLEANUP="n"
echo
if [[ $CLEANUP =~ ^[Yy]$ ]]; then
    rm -f "$DOWNLOAD_DIR/$FILE_A"
    rm -f "$DOWNLOAD_DIR/$FILE_B"
    rm -f "$DOWNLOAD_DIR/$MERGED_FILE"
    echo -e "${GREEN}✓ Cleanup completed${NC}"
else
    echo -e "${YELLOW}Archives kept in $DOWNLOAD_DIR${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Data location: ${GREEN}$FINAL_DIR${NC}"
echo -e "PointLLM link: ${GREEN}$POINTLLM_DIR/data/objaverse_data${NC}"
echo -e "Number of files: ${GREEN}$FILE_COUNT${NC}"
