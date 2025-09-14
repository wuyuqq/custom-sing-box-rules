#!/bin/bash
list=($(ls ./rules/))

# 将文本文件包装成 JSON 数组
wrap_json() {
    local file=$1 key=$2
    [ -f "$file" ] || return
    sed -i 's/^/        "/' "$file"
    sed -i 's/$/",/' "$file"
    sed -i "1s/^/      \"$key\": [\n/" "$file"
    sed -i '$ s/,$/\n      ],/g' "$file"
}

for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"
    yaml="./rules/${list[i]}/${list[i]}.yaml"

    # 定义规则类型与对应前缀
    declare -A rules=(
        ["domain"]="DOMAIN,"
        ["suffix"]="DOMAIN-SUFFIX,"
        ["keyword"]="DOMAIN-KEYWORD,"
        ["ipcidr"]="IP-CIDR"
    )

    # 归类并生成临时 JSON
    for key 在 "${!rules[@]}"; do
        prefix=${rules[$key]}
        file="${list[i]}/$key.json"
        if grep -q "^$prefix" "$yaml"; then
            if [ "$key" == "ipcidr" ]; then
                grep '^IP-CIDR' "$yaml" | sed -e 's/^IP-CIDR,//' -e 's/^IP-CIDR6,//' -e 's/,no-resolve//' > "$file"
            else
                grep "^$prefix" "$yaml" | sed "s/^$prefix//" > "$file"
            fi
            wrap_json "$file" "$key"
        fi
    done

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
