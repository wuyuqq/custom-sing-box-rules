#!/bin/bash
# 处理 rules 文件夹下的 YAML 文件，生成 JSON 并编译成 sing-box srs

set -e
shopt -s nullglob

format_json() {
    local file=$1
    local key=$2
    [ -f "$file" ] || return
    sed -i 's/^/        "/; s/$/",/' "$file"
    sed -i "1s/^/      \"$key\": [\n/" "$file"
    sed -i '$ s/,$/\n      ],/' "$file"
}

merge_json() {
    local filename=$1
    local out="$filename.json"
    [ -f "$out" ] && rm -f "$out"
    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "$filename/domain.json" ] && cat "$filename/domain.json"
        [ -f "$filename/suffix.json" ] && cat "$filename/suffix.json"
        [ -f "$filename/keyword.json" ] && cat "$filename/keyword.json"
        [ -f "$filename/ipcidr.json" ] && cat "$filename/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$out"
}

# 遍历 rules 文件夹
for yaml_dir 在 ./rules/*/; do
    [ -d "$yaml_dir" ] || continue
    filename=$(basename "$yaml_dir")
    yaml_file="$yaml_dir/$filename.yaml"
    mkdir -p "$filename"

    # 生成临时 JSON 文件
    grep 'DOMAIN-SUFFIX,' "$yaml_file" | sed 's/^DOMAIN-SUFFIX,//' > "$filename/suffix.json" || true
    grep 'DOMAIN,' "$yaml_file" | sed 's/^DOMAIN,//' > "$filename/domain.json" || true
    grep 'DOMAIN-KEYWORD,' "$yaml_file" | sed 's/^DOMAIN-KEYWORD,//' > "$filename/keyword.json" || true
    grep -E 'IP-CIDR|IP-CIDR6' "$yaml_file" | sed -E 's/^IP-CIDR6?,//; s/,no-resolve//' > "$filename/ipcidr.json" || true

    # 格式化 JSON
    format_json "$filename/domain.json" "domain"
    format_json "$filename/suffix.json" "domain_suffix"
    format_json "$filename/keyword.json" "domain_keyword"
    format_json "$filename/ipcidr.json" "ip_cidr"

    # 合并 JSON
    merge_json "$filename"

    # 编译 sing-box srs
    ./sing-box rule-set compile "$filename.json" -o "$filename.srs"

    # 清理临时文件夹
    rm -rf "$filename"
done
