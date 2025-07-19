#!/bin/sh

ROOTFS_DIR=/home/container
PROOT_VERSION="5.3.0"
# =========================================================================================
# Логика установки при первом запуске
# =========================================================================================
if [ ! -e $ROOTFS_DIR/.installed ]; then
    # Очищаем экран для меню выбора
    clear

    # Переменные для URL и сообщения
    ROOTFS_URL=""
    PLACEHOLDER_MSG=""
    ARCH=$(uname -m)
    # --- Меню выбора дистрибутива ---
    echo "Выберите дистрибутив для установки:"
    echo "[1] Ubuntu"
    echo "[2] Alpine"
    
    read -p "Ваш выбор [1-2]: " DISTRO_CHOICE
    
    case $DISTRO_CHOICE in
        1) # Пользователь выбрал Ubuntu
            # --- Меню выбора версии Ubuntu ---

            case "${ARCH}" in
                "x86_64")
                    URL_ARCH="amd64"
                    ;;
                "aarch64")
                    URL_ARCH="arm64"
                    ;;
                *)
                    # Фоллбэк, если архитектура другая
                    URL_ARCH="${ARCH}"
                    ;;
            esac
            echo ""
            echo "Выберите версию Ubuntu LTS:"
            echo "[1] Ubuntu 24.04 LTS (Noble Numbat) - LATEST"
            echo "[2] Ubuntu 22.04 LTS (Jammy Jellyfish)"
            echo "[3] Ubuntu 20.04 LTS (Focal Fossa)"
            echo "[4] Ubuntu 18.04 LTS (Bionic Beaver)"
            echo "[5] Ubuntu 16.04 LTS (Xenial Xerus)"
            
            read -p "Ваш выбор [1-5]: " UBUNTU_CHOICE

            case $UBUNTU_CHOICE in
                1)
                    ROOTFS_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-${URL_ARCH}-root.tar.xz"
                    ;;
                2)
                    ROOTFS_URL="https://cloud-images.ubuntu.com/jammy/current/ubuntu-jammy-cloudimg-${URL_ARCH}-root.tar.gz"
                    ;;
                3)
                    ROOTFS_URL="https://cloud-images.ubuntu.com/focal/current/ubuntu-focal-cloudimg-${URL_ARCH}-root.tar.gz"
                    ;;
                4)
                    ROOTFS_URL="https://cloud-images.ubuntu.com/bionic/current/ubuntu-bionic-cloudimg-${URL_ARCH}-root.tar.gz"
                    ;;
                5)
                    ROOTFS_URL="https://cloud-images.ubuntu.com/xenial/current/ubuntu-xenial-cloudimg-${URL_ARCH}-root.tar.gz"
                    ;;
                *)
                    echo "Ошибка: Неверный выбор версии Ubuntu."
                    exit 1
                    ;;
            esac
            ;;
        2) # Пользователь выбрал Debian
            echo ""
            echo "Выберите версию Alpine:"
            echo "[1] Alpine 3.20 - LATEST"
            echo "[2] Alpine 3.19"
            echo "[3] Alpine 3.18"
            echo "[4] Alpine 3.17"
            echo "[5] Alpine 3.14"
            echo "[6] Alpine 3.11"
            echo "[7] Alpine 3.8"
            echo "[8] Alpine 3.5"
            
            read -p "Ваш выбор [1-5]: " ALPINE_CHOICE

            case $ALPINE_CHOICE in
                1)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/${ARCH}/alpine-minirootfs-3.22.0-${ARCH}.tar.gz"
                    ;;
                2)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/${ARCH}/alpine-minirootfs-3.19.7-${ARCH}.tar.gz"
                    ;;
                3)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/${ARCH}/alpine-minirootfs-3.18.9-${ARCH}.tar.gz"
                    ;;
                4)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.17/releases/${ARCH}/alpine-minirootfs-3.17.9-${ARCH}.tar.gz"
                    ;;
                5)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.14/releases/${ARCH}/alpine-minirootfs-3.14.10-${ARCH}.tar.gz"
                    ;;
                6)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.11/releases/${ARCH}/alpine-minirootfs-3.11.13-${ARCH}.tar.gz"
                    ;;
                7)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.8/releases/${ARCH}/alpine-minirootfs-3.8.5-${ARCH}.tar.gz"
                    ;;
                8)
                    ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.5/releases/${ARCH}/alpine-minirootfs-3.5.3-${ARCH}.tar.gz"
                    ;;
                *)
                    echo "Ошибка: Неверный выбор версии Ubuntu."
                    exit 1
                    ;;
            esac
            ;;
        *) # Неверный выбор
            echo "Ошибка: Неверный выбор дистрибутива."
            exit 1
            ;;
    esac

    # --- Загрузка и распаковка выбранного дистрибутива ---
    clear
    echo "${PLACEHOLDER_MSG}"
    echo "Загрузка корневой файловой системы... Это может занять некоторое время."
    
    # Скачиваем архив
    if curl -L -o /tmp/rootfs.tar.gz "${ROOTFS_URL}"; then
        echo "Загрузка завершена."
    else
        echo "Ошибка: Не удалось скачать корневую файловую систему. Проверьте URL и подключение к сети."
        exit 1
    fi
    
    # Распаковываем архив
    echo "Распаковка... "
    # Ubuntu использует .tar.gz, Debian LxC - .tar.xz. Эта проверка обрабатывает оба случая.
    if tar -I 'gzip' -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR; then
        echo "Распаковка завершена."
    else
        echo "Ошибка: Не удалось распаковать архив."
        exit 1
    fi
fi

################################
# Package Installation & Setup #
################################

# Скачиваем дополнительные утилиты, если они еще не установлены.
# Эта логика выполняется в том же блоке if, что и установка дистрибутива.
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "Установка дополнительных утилит (proot)..."
    
    curl -Lo $ROOTFS_DIR/usr/local/bin/proot "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# =========================================================================================
# Финальная настройка и очистка
# =========================================================================================
if [ ! -e $ROOTFS_DIR/.installed ]; then
    echo "Финальная настройка..."
    # Добавляем DNS серверы в resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    
    # Удаляем временные файлы
    rm -f /tmp/rootfs.tar.gz
    
    # Создаем файл .installed, чтобы эта логика не выполнялась при следующих запусках.
    touch $ROOTFS_DIR/.installed
fi

# Выводим приветственное сообщение
clear && cat << EOF
PteroVM is started!
Вы вошли в окружение выбранного дистрибутива.
Для установки пакетов используйте 'apt update && apt install ...'
EOF

###########################
# Start PRoot environment #
###########################

# Эта команда запускает PRoot и "монтирует" важные директории
# из хост-системы в нашу корневую файловую систему.
$ROOTFS_DIR/usr/local/bin/proot \
    --rootfs="${ROOTFS_DIR}" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/bash