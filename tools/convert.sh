# 处理文件
list=($(ls ./rules/))
for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"

    # 归类
    if grep -q 'DOMAIN-SUFFIX,' ./rules/${list[i]}/${list[i]}.yaml; then
        grep 'DOMAIN-SUFFIX,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-SUFFIX,//g' > ${list[i]}/suffix.json
    fi
    if grep -q 'DOMAIN,' ./rules/${list[i]}/${list[i]}.yaml; then
        grep 'DOMAIN,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN,//g' >> ${list[i]}/domain.json
    fi
    if grep -q 'DOMAIN-KEYWORD,' ./rules/${list[i]}/${list[i]}.yaml; then
        grep 'DOMAIN-KEYWORD,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-KEYWORD,//g' > ${list[i]}/keyword.json
    fi
    if grep -q 'IP-CIDR' ./rules/${list[i]}/${list[i]}.yaml; then
        grep 'IP-CIDR' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^IP-CIDR,//g;s/^IP-CIDR6,//g;s/,no-resolve//g' > ${list[i]}/ipcidr.json
    fi

    # 需要处理的类型和对应 key
    declare -A json_keys=(
        [domain]="domain"
        [suffix]="domain_suffix"
        [keyword]="domain_keyword"
        [ipcidr]="ip_cidr"
    )

    # 转成 json 格式
    for k in domain suffix keyword ipcidr; do
        file="${list[i]}/$k.json"
        if [ -f "$file" ]; then
            sed -i 's/^/        "/;s/$/",/' "$file"
            sed -i "1s/^/      \"${json_keys[$k]}\": [\n/" "$file"
            sed -i '$ s/,$/\n      ],/' "$file"
        fi
    done

    # 合并顺序：domain → suffix → keyword → ipcidr
    if [ "$(ls ${list[i]})" = "" ]; then
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' ${list[i]}.json
    elif [ -f "${list[i]}.json" ]; then
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' ${list[i]}.json
        sed -i '$ s/,$/\n    },\n    {/' ${list[i]}.json
        for k in domain suffix keyword ipcidr; do
            [ -f "${list[i]}/$k.json" ] && cat ${list[i]}/$k.json >> ${list[i]}.json
        done
    else
        for k in domain suffix keyword ipcidr; do
            [ -f "${list[i]}/$k.json" ] && cat ${list[i]}/$k.json >> ${list[i]}.json
        done
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' ${list[i]}.json
    fi

    # 结尾修复
    sed -i '$ s/,$/\n    }\n  ]\n}/' ${list[i]}.json

    # 清理
    rm -r ${list[i]}
    ./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
