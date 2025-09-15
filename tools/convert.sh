# 处理文件
list=($(ls ./rules/))
for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"

    # 归类，直接 grep 输出，不再额外 -q 检查
    grep 'DOMAIN-SUFFIX,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-SUFFIX,//' > ${list[i]}/suffix.json
    grep 'DOMAIN,'        ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN,//'       > ${list[i]}/domain.json
    grep 'DOMAIN-KEYWORD,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-KEYWORD,//' > ${list[i]}/keyword.json
    grep 'IP-CIDR'        ./rules/${list[i]}/${list[i]}.yaml | sed 's/^IP-CIDR,//;s/^IP-CIDR6,//;s/,no-resolve//g' > ${list[i]}/ipcidr.json

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
        if [ -s "$file" ]; then
            sed -i -e 's/^/        "/' \
                   -e 's/$/",/' \
                   -e "1s/^/      \"${json_keys[$k]}\": [\n/" \
                   -e '$ s/,$/\n      ],/' "$file"
        else
            rm -f "$file" # 空文件删除，避免污染
        fi
    done

    # 合并顺序：domain → suffix → keyword → ipcidr
    if [ -f "${list[i]}.json" ]; then
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' ${list[i]}.json
        sed -i '$ s/,$/\n    },\n    {/' ${list[i]}.json
    else
        echo "" > ${list[i]}.json
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' ${list[i]}.json
    fi
    for k in domain suffix keyword ipcidr; do
        [ -f "${list[i]}/$k.json" ] && cat ${list[i]}/$k.json >> ${list[i]}.json
    done

    # 结尾修复
    sed -i '$ s/,$/\n    }\n  ]\n}/' ${list[i]}.json

    # 清理
    rm -r ${list[i]}
    ./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
