# 处理文件
list=($(ls ./rules/))
for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p ${list[i]}

    # 归类
    yaml="./rules/${list[i]}/${list[i]}.yaml"

    # domain
    if [ -n "$(grep 'DOMAIN,' "$yaml")" ]; 键，然后
        grep 'DOMAIN,' "$yaml" | sed 's/^DOMAIN,//' > ${list[i]}/domain.json
    fi
    if [ -n "$(grep 'DOMAIN-SUFFIX,' "$yaml")" ]; 键，然后
        grep 'DOMAIN-SUFFIX,' "$yaml" | sed 's/^DOMAIN-SUFFIX,//' > ${list[i]}/suffix.json
    fi
    if [ -n "$(grep 'DOMAIN-KEYWORD,' "$yaml")" ]; then
        grep 'DOMAIN-KEYWORD,' "$yaml" | sed 's/^DOMAIN-KEYWORD,//' > ${list[i]}/keyword.json
    fi
    # ipcidr
    if [ -n "$(grep 'IP-CIDR' "$yaml")" ]; then
        grep 'IP-CIDR' "$yaml" \
            | sed -e 's/^IP-CIDR,//' -e 's/^IP-CIDR6,//' -e 's/,no-resolve//' > ${list[i]}/ipcidr.json
    fi

    # 转成 JSON
    wrap() {
        [ -f "$1" ] || return
        sed -i 's/^/        "/' "$1"
        sed -i 's/$/",/' "$1"
        sed -i "1s/^/      \"$2\": [\n/" "$1"
        sed -i '$ s/,$/\n      ],/g' "$1"
    }

    wrap "${list[i]}/domain.json" "domain"
    wrap "${list[i]}/suffix.json" "domain_suffix"
    wrap "${list[i]}/keyword.json" "domain_keyword"
    wrap "${list[i]}/ipcidr.json" "ip_cidr"

    # 合并 JSON 顺序：domain → suffix → keyword → ip_cidr（ip_cidr 最后）
    json_file="${list[i]}.json"
    [ -f "$json_file" ] && rm -f "$json_file"

    {
        echo "{"
        echo "  \"version\": 1,"
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

    # 删除最后一个数组的多余逗号
    sed -i -E ':a;N;$!ba;s/,\n([[:space:]]*")/\n\1/g' "$json_file"

    # 清理临时文件夹并生成 srs
    rm -r "${list[i]}"
    ./sing-box rule-set compile "$json_file" -o "${list[i]}.srs"
done
