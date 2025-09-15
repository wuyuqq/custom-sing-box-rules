#!/bin/bash
# 处理文件
for dir in ./rules/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    mkdir -p "$name"

    # 归类
    grep 'DOMAIN-SUFFIX,' "$dir/$name.yaml" | sed 's/^DOMAIN-SUFFIX,//' > "$name/suffix.json"
    grep 'DOMAIN,' "$dir/$name.yaml" | sed 's/^DOMAIN,//' > "$name/domain.json"
    grep 'DOMAIN-KEYWORD,' "$dir/$name.yaml" | sed 's/^DOMAIN-KEYWORD,//' > "$name/keyword.json"
    grep 'IP-CIDR' "$dir/$name.yaml" | sed 's/^IP-CIDR,//;s/^IP-CIDR6,//;s/,no-resolve//' > "$name/ipcidr.json"

    # json key 映射
    declare -A json_keys=( [domain]="domain" [suffix]="domain_suffix" [keyword]="domain_keyword" [ipcidr]="ip_cidr" )

    # 合并 JSON 文件
    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"

        for k in domain suffix keyword ipcidr; do
            file="$name/$k.json"
            if [ -s "$file" ]; then
                echo "      \"${json_keys[$k]}\": ["
                sed 's/^/        "/;s/$/",/' "$file" | sed '$ s/,$//'
                echo "      ],"
            fi
        done

        # 删除最后多余逗号
        sed '$ s/,$//' <<< "" # 这里不需要再操作文件，后续 echo 直接闭合
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    # 清理临时文件
    rm -r "$name"

    # 编译 srs 文件
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
