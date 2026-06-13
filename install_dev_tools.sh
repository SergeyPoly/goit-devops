#!/bin/bash

# Завершать выполнение, если какая-то команда завершилась ошибкой
set -e

echo "=== Начало настройки окружения ==="

# Обновляем списки пакетов
echo "Обновление индексов пакетов..."
sudo apt-get update -y

# Функция для проверки наличия команды
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Проверка и установка Docker
if is_installed docker; then
    echo "✓ Docker уже установлен: $(docker --version)"
else
    echo "Установка Docker..."
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    echo "✓ Docker успешно установлен!"
fi

# 2. Проверка и установка Docker Compose (плагин или бинарник)
if is_installed docker-compose; then
    echo "✓ Docker Compose уже установлен: $(docker-compose --version)"
elif docker compose version >/dev/null 2>&1; then
    echo "✓ Docker Compose (как плагин CLI) уже установлен: $(docker compose version)"
else
    echo "Установка Docker Compose..."
    # Устанавливаем актуальную версию через GitHub репозиторий
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K[^"]*')
    sudo curl -L "https://github.com/docker/compose/releases/download/${VER}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose успешно установлен!"
fi

# 3. Проверка и установка Python 3 (минимум 3.9)
if is_installed python3; then
    # Получаем полную версию, например, "3.12.3"
    PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}")')

    # Надежное сравнение версий с помощью sort -V
    # Если минимальная версия (3.9.0) идет первой в отсортированном списке, значит установленная версия равна или новее.
    if [ "$(printf '%s\n%s' "3.9.0" "$PYTHON_VER" | sort -V | head -n1)" = "3.9.0" ]; then
        echo "✓ Python 3 (версия $PYTHON_VER) уже установлен и соответствует требованиям (>= 3.9)."
    else
        echo "Установленная версия Python ($PYTHON_VER) ниже 3.9. Обновление..."
        sudo apt-get install -y python3 python3-pip python3-venv
    fi
else
    echo "Установка Python 3 и pip..."
    sudo apt-get install -y python3 python3-pip python3-venv
    echo "✓ Python 3 успешно установлен!"
fi

# Обеспечиваем наличие pip для дальнейшей установки Django
if ! is_installed pip3; then
    echo "Установка pip3..."
    sudo apt-get install -y python3-pip
fi

# 4. Проверка и установка Django
if python3 -c "import django" >/dev/null 2>&1; then
    echo "✓ Django уже установлен: $(python3 -m django --version)"
else
    echo "Установка Django через pip..."
    # Используем --break-system-packages, если это современные версии Ubuntu (23.04+),
    # либо скрипт просто поставит глобально на более старых версиях.
    pip3 install django --break-system-packages || pip3 install django
    echo "✓ Django успешно установлен: $(python3 -m django --version)"
fi

echo "=== Настройка успешно завершена! ==="