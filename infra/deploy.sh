#!/bin/sh
# A1 (jp-browser-1) へ AdGuard Home を冪等に設置するスクリプト（雛形）
# 既存サービス（photoshare 等）には触らない。localhost の高ポートのみ使う。
set -eu
AGH_VERSION="${AGH_VERSION:-v0.107.72}"
AGH_HOME="${AGH_HOME:-$HOME/adguardhome}"
mkdir -p "$AGH_HOME"
echo "TODO: AdGuard Home ${AGH_VERSION} を取得し ${AGH_HOME} に配置"
echo "TODO: AdGuardHome.yaml.template から設定を生成"
echo "TODO: systemd ユーザーサービスとして登録（DNS 127.0.0.1:3053 / 管理 127.0.0.1:3000）"
