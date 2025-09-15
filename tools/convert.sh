# 处理文件
for dir in ./rules/*; do
    name=$(basename "$dir")
    mkdir -p "$name"

    # 归类
    if grep -q 'DOMAIN-SUFFIX,' "$dir/$name.yaml"; then
        grep 'DOMAIN-SUFFIX,' "$dir/$name.yaml" | sed 's/^DOMAIN-SUFFIX,//g' > "$name/suffix.json"
    fi
    if grep -q 'DOMAIN,' "$dir/$name.yaml"; then
        grep 'DOMAIN,' "$dir/$name.yaml" | sed 's/^DOMAIN,//g' > "$name/domain.json"
    fi
    if grep -q 'DOMAIN-KEYWORD,' "$dir/$name.yaml"; then
        grep 'DOMAIN-KEYWORD,' "$dir/$name.yaml" | sed 's/^DOMAIN-KEYWORD,//g' > "$name/keyword.json"
    fi
    if grep -q 'IP-CIDR' "$dir/$name.yaml"; then
        grep 'IP-CIDR' "$dir/$name.yaml" | sed 's/^IP-CIDR,//g;s/^IP-CIDR6,//g;s/,no-resolve//g' > "$name/ipcidr.json"
    fi

    # json keys 对应
    declare -A json_keys=(
        [domain]="domain"
        [suffix]="domain_suffix"
        [keyword]="domain_keyword"
        [ipcidr]="ip_cidr"
    )

    # 转成 json 格式
    for k 在 domain suffix keyword ipcidr; do
        file="$name/$k.json"
        if [ -f "$file" ]; then
            sed -i 's/^/        "/;s/$/",/' "$file"
            sed -i "1s/^/      \"${json_keys[$k]}\": [\n/" "$file"
            sed -i '$ s/,$/\n      ],/' "$file"
        fi
    done

    # 合并顺序：domain → suffix → keyword → ipcidr
    json_file="$name.json"
    echo -e "{\n  \"version\": 2,\n  \"rules\": [\n    {" > "$json_file"
    for k in domain suffix keyword ipcidr; do
        [ -f "$name/$k.json" ] && cat "$name/$k.json" >> "$json_file"
    done
    sed -i '$ s/,$/\n    }\n  ]\n}/' "$json_file"

    # 清理
    rm -r "$name"
    ./sing-box rule-set compile "$json_file" -o "$name.srs"
done
