#!/bin/bash
list=($(ls ./rules/))

# 转换单个文件为 JSON 数组片段
# $1 = 输入文件, $2 = key 名
to_json_array() {
    local file=$1 key=$2
    [ -f "$file" ] || return
    sed -i 's/^/        "/g' "$file"
    sed -i 's/$/",/g' "$file"
    sed -i "1s/^/      \"$key\": [\n/" "$file"
    sed -i '$ s/,$/\n      ],/g' "$file"
}

for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"

    yaml="./rules/${list[i]}/${list[i]}.yaml"

    # 分类提取
    grep '^DOMAIN-SUFFIX,' "$yaml" | sed 's/^DOMAIN-SUFFIX,//' > "${list[i]}/suffix.json" || true
    grep '^DOMAIN,' "$yaml"        | sed 's/^DOMAIN,//'        > "${list[i]}/domain.json" || true
    grep '^DOMAIN-KEYWORD,' "$yaml"| sed 's/^DOMAIN-KEYWORD,//'> "${list[i]}/keyword.json" || true
    grep '^IP-CIDR' "$yaml"        | sed -e 's/^IP-CIDR,//' \
                                      -e 's/^IP-CIDR6,//' \
                                      -e 's/,no-resolve//'   > "${list[i]}/ipcidr.json" || true

    # 转成 JSON 格式
    to_json_array "${list[i]}/domain.json"  "domain"
    to_json_array "${list[i]}/suffix.json"  "domain_suffix"
    to_json_array "${list[i]}/keyword.json" "domain_keyword"
    to_json_array "${list[i]}/ipcidr.json"  "ip_cidr"

    # 合并 JSON
    json_file="${list[i]}.json"
    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "${list[i]}/domain.json"  ] && cat "${list[i]}/domain.json"
        [ -f "${list[i]}/suffix.json"  ] && cat "${list[i]}/suffix.json"
        [ -f "${list[i]}/keyword.json" ] && cat "${list[i]}/keyword.json"
        [ -f "${list[i]}/ipcidr.json"  ] && cat "${list[i]}/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$json_file"

    # 清理临时目录并编译
    rm -r "${list[i]}"
    ./sing-box rule-set compile "$json_file" -o "${list[i]}.srs"
done
