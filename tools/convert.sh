#!/bin/bash
set -e

# 遍历 rules 目录
for rule in ./rules/*; do
    name=$(basename "$rule")
    mkdir -p "$name"

    # 提取各类规则
    awk -F, '/^DOMAIN-SUFFIX,/ {print $2}' "$rule/$name.yaml" > "$name/suffix.json"
    awk -F, '/^DOMAIN,/ {print $2}' "$rule/$name.yaml" > "$name/domain.json"
    awk -F, '/^DOMAIN-KEYWORD,/ {print $2}' "$rule/$name.yaml" > "$name/keyword.json"
    awk -F, '/^IP-CIDR/ {gsub(/,no-resolve/,""); gsub(/^IP-CIDR6?/,""); print $2}' "$rule/$name.yaml" > "$name/ipcidr.json"

    # JSON 封装函数
    json_wrap() {
        local file="$1"
        local key="$2"
        [ -f "$file" ] || return
        sed -e 's/^/        "/' -e 's/$/",/' "$file" | awk -v k="$key" 'BEGIN{print "      \""k"\": ["} {print} END{print "      ],"}'
    }

    # 合并 JSON（顺序 domain → suffix → keyword → ipcidr）
    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        json_wrap "$name/domain.json" "domain"
        json_wrap "$name/suffix.json" "domain_suffix"
        json_wrap "$name/keyword.json" "domain_keyword"
        json_wrap "$name/ipcidr.json" "ip_cidr"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    # 清理临时目录
    [ -d "$name" ] && rm -r "$name"

    # 编译 sing-box 规则
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
