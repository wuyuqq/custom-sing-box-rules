#!/bin/bash
set -e

json_wrap() {
    local file=$1
    local key=$2
    [ -f "$file" ] || return
    sed -i 's/^/        "/' "$file"
    sed -i 's/$/",/' "$file"
    sed -i "1s/^/      \"$key\": [\n/" "$file"
    sed -i '$ s/,$/\n      ],/' "$file"
}

for rule 在 ./rules/*; do
    name=$(basename "$rule")
    mkdir -p "$name"

    # 归类
    awk -F, '/^DOMAIN-SUFFIX,/ {print $2}' "$rule/$name.yaml" > "$name/suffix.json"
    awk -F, '/^DOMAIN,/ {print $2}' "$rule/$name.yaml" > "$name/domain.json"
    awk -F, '/^DOMAIN-KEYWORD,/ {print $2}' "$rule/$name.yaml" > "$name/keyword.json"
    awk -F, '/^IP-CIDR/ {gsub(/,no-resolve/,""); gsub(/^IP-CIDR6?/,""); print $2}' "$rule/$name.yaml" > "$name/ipcidr.json"

    # 转成 json
    json_wrap "$name/domain.json" "domain"
    json_wrap "$name/suffix.json" "domain_suffix"
    json_wrap "$name/keyword.json" "domain_keyword"
    json_wrap "$name/ipcidr.json" "ip_cidr"

    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "$name/domain.json" ] && cat "$name/domain.json"
        [ -f "$name/suffix.json" ] && cat "$name/suffix.json"
        [ -f "$name/keyword.json" ] && cat "$name/keyword.json"
        [ -f "$name/ipcidr.json" ] && cat "$name/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    rm -r "$name"
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
