#!/bin/bash

# Install the project's requirements.txt, cached in .wheel in project directory.
# 指定requirements.txt文件的路径
requirements_file="/app/requirements.txt"

# .wheels目录
wheel_dir="/app/.wheels"

# 指定存储先前MD5值的文件路径
md5_file="/app/.wheels/requirements.md5"

function pip_install() {
    echo "[*] Wheels not downloaded, downloading..."
    pip wheel --no-cache-dir --wheel-dir=$wheel_dir -r $requirements_file
}

if [ -f "$requirements_file" ]; then
    # 计算requirements.txt文件的当前MD5值
    current_md5=$(md5sum "$requirements_file" | awk '{print $1}')

    if [ ! -d "$wheel_dir" ]; then
        pip_install
        echo "$current_md5" > "$md5_file"
    else
        # 检查存储先前MD5值的文件是否存在
        if [ -f "$md5_file" ]; then
            # 读取先前的MD5值
            previous_md5=$(cat "$md5_file")

            # 比较当前MD5值和先前的MD5值
            if [ "$current_md5" != "$previous_md5" ]; then
                pip_install
                echo "$current_md5" > "$md5_file"
            else
                echo "[*] Wheels already downloaded, skipping..."
            fi
        else
            # 如果存储先前MD5值的文件不存在，将当前MD5值写入文件
            echo "$current_md5" > "$md5_file"
            pip_install
        fi
    fi
    echo "[*] Installing..."
    pip install --no-index --find-links=/app/.wheels -r /app/requirements.txt
    echo "[*] Python packages installed."
    echo "[*] Current Django version: $(python -c "import django; print(django.get_version())")"

fi

exec "$@"