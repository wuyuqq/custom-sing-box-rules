# 处理文件
list=($(ls ./rules/))
for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p ${list[i]}
    # 归类
    # domain
    if [ -n "$(grep 'DOMAIN-SUFFIX,' ./rules/${list[i]}/${list[i]}.yaml)" ]; then
        grep 'DOMAIN-SUFFIX,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-SUFFIX,//g' > ${list[i]}/suffix.json
    fi
    if [ -n "$(grep 'DOMAIN,' ./rules/${list[i]}/${list[i]}.yaml)" ]; then
        grep 'DOMAIN,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN,//g' > ${list[i]}/domain.json
    fi
    if [ -n "$(grep 'DOMAIN-KEYWORD,' ./rules/${list[i]}/${list[i]}.yaml)" ]; then
        grep 'DOMAIN-KEYWORD,' ./rules/${list[i]}/${list[i]}.yaml | sed 's/^DOMAIN-KEYWORD,//g' > ${list[i]}/keyword.json
    fi
    # ipcidr
    if [ -n "$(grep 'IP-CIDR' ./rules/${list[i]}/${list[i]}.yaml)" ]; then
        grep 'IP-CIDR' ./rules/${list[i]}/${list[i]}.yaml \
            | sed 's/^IP-CIDR,//g' \
            | sed 's/^IP-CIDR6,//g' \
            | sed 's/,no-resolve//g' > ${list[i]}/ipcidr.json
    fi

    # 转成json格式
    # domain
    if [ -f "${list[i]}/domain.json" ]; then
        sed -i 's/^/        "/g' ${list[i]}/domain.json
        sed -i 's/$/",/g' ${list[i]}/domain.json
        sed -i '1s/^/      "domain": [\n/g' ${list[i]}/domain.json
        sed -i '$ s/,$/\n      ],/g' ${list[i]}/domain.json
    fi
    if [ -f "${list[i]}/suffix.json" ]; then
        sed -i 's/^/        "/g' ${list[i]}/suffix.json
        sed -i 's/$/",/g' ${list[i]}/suffix.json
        sed -i '1s/^/      "domain_suffix": [\n/g' ${list[i]}/suffix.json
        sed -i '$ s/,$/\n      ],/g' ${list[i]}/suffix.json
    fi
    if [ -f "${list[i]}/keyword.json" ]; then
        sed -i 's/^/        "/g' ${list[i]}/keyword.json
        sed -i 's/$/",/g' ${list[i]}/keyword.json
        sed -i '1s/^/      "domain_keyword": [\n/g' ${list[i]}/keyword.json
        sed -i '$ s/,$/\n      ],/g' ${list[i]}/keyword.json
    fi
    # ipcidr
    if [ -f "${list[i]}/ipcidr.json" ]; then
        sed -i 's/^/        "/g' ${list[i]}/ipcidr.json
        sed -i 's/$/",/g' ${list[i]}/ipcidr.json
        sed -i '1s/^/      "ip_cidr": [\n/g' ${list[i]}/ipcidr.json
        sed -i '$ s/,$/\n      ],/g' ${list[i]}/ipcidr.json
    fi

    # 合并 json 顺序：domain → suffix → keyword → ipcidr
    if [ -f "${list[i]}.json" ]; then
        rm -f ${list[i]}.json
    fi
    {
        echo "{"
        echo "  \"version\": 1,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "${list[i]}/domain.json" ] && cat ${list[i]}/domain.json
        [ -f "${list[i]}/suffix.json" ] && cat ${list[i]}/suffix.json
        [ -f "${list[i]}/keyword.json" ] && cat ${list[i]}/keyword.json
        [ -f "${list[i]}/ipcidr.json" ] && cat ${list[i]}/ipcidr.json
        echo "    }"
        echo "  ]"
        echo "}"
    } > ${list[i]}.json

    rm -r ${list[i]}
    ./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
