#!/bin/bash
list=($(ls ./rules/))

wrap_json() {
    # $1 = 文件路径, $2 = JSON key
    local file=$1 key=$2
    [ -f "$file" ] || return
    sed -i 's/^/        "/' "$file"
    sed -i 's/$/",/' "$file"
    sed -i "1s/^/      \"$key\": [\n/" "$file"
    sed -i '$ s/,$/\n      ],/' "$file"
}

for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"

    yaml="./rules/${list[i]}/${list[i]}.yaml"

    # domain 归类
    grep '^DOMAIN-SUFFIX,' "$yaml" | sed 's/^DOMAIN-SUFFIX,//' > "${list[i]}/suffix.json" || true
    grep '^DOMAIN,' "$yaml" | sed 's/^DOMAIN,//' > "${list[i]}/domain.json" || true
    grep '^DOMAIN-KEYWORD,' "$yaml" | sed 's/^DOMAIN-KEYWORD,//' > "${list[i]}/keyword.json" || true
    grep '^IP-CIDR' "$yaml" | sed -e 's/^IP-CIDR,//' -e 's/^IP-CIDR6,//' -e 's/,no-resolve//' > "${list[i]}/ipcidr.json" || true

    # 转成 JSON
    wrap_json "${list[i]}/domain.json" "domain"
    wrap_json "${list[i]}/suffix.json" "domain_suffix"
    wrap_json "${list[i]}/keyword.json" "domain_keyword"
    wrap_json "${list[i]}/ipcidr.json" "ip_cidr"

    # 合并 JSON
    json_file="${list[i]}.json"
    [ -f "$json_file" ] && rm -f "$json_file"

    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "${list[i]}/domain.json" ] && cat "${list[i]}/domain.json"
        [ -f "${list[i]}/suffix.json" ] && cat "${list[i]}/suffix.json"
        [ -f "${list[i]}/keyword.json" ] && cat "${list[i]}/keyword.json"
        [ -f "${list[i]}/ipcidr.json" ] && cat "${list[i]}/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$json_file"

    # 清理临时文件夹并生成 srs
    rm -r "${list[i]}"
    ./sing-box rule-set compile "$json_file" -o "${list[i]}.srs"
done
