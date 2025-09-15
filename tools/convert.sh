#!/bin/bash

# 遍历 rules 目录
for dir in ./rules/*; do
    [ -d "$dir" ] || continue
    list_i=$(basename "$dir")
    mkdir -p "$list_i"

    yaml_file="$dir/$list_i.yaml"

    # 归类
    grep -q 'DOMAIN-SUFFIX,' "$yaml_file" && grep 'DOMAIN-SUFFIX,' "$yaml_file" | sed 's/^DOMAIN-SUFFIX,//' > "$list_i/suffix.json"
    grep -q 'DOMAIN,' "$yaml_file" && grep 'DOMAIN,' "$yaml_file" | sed 's/^DOMAIN,//' >> "$list_i/domain.json"
    grep -q 'DOMAIN-KEYWORD,' "$yaml_file" && grep 'DOMAIN-KEYWORD,' "$yaml_file" | sed 's/^DOMAIN-KEYWORD,//' > "$list_i/keyword.json"
    grep -q 'IP-CIDR' "$yaml_file" && grep 'IP-CIDR' "$yaml_file" | sed 's/^IP-CIDR,//;s/^IP-CIDR6,//;s/,no-resolve//' > "$list_i/ipcidr.json"

    # 类型对应 key
    declare -A json_keys=( [domain]="domain" [suffix]="domain_suffix" [keyword]="domain_keyword" [ipcidr]="ip_cidr" )

    # 转成 JSON
    for k in domain suffix keyword ipcidr; do
        file="$list_i/$k.json"
        [ -f "$file" ] || continue
        sed -i '1s/^/      "'"${json_keys[$k]}"'": [\n/;s/^/        "/;s/$/",/;$ s/,$/\n      ],/' "$file"
    done

    # 合并顺序：domain → suffix → keyword → ipcidr
    if [ -f "$list_i.json" ]; then
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' "$list_i.json"
        sed -i '$ s/,$/\n    },\n    {/' "$list_i.json"
        for k in domain suffix keyword ipcidr; do
            [ -f "$list_i/$k.json" ] && cat "$list_i/$k.json" >> "$list_i.json"
        done
    else
        for k in domain suffix keyword ipcidr; do
            [ -f "$list_i/$k.json" ] && cat "$list_i/$k.json" >> "$list_i.json"
        done
        sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/' "$list_i.json"
    fi

    # 修复结尾
    sed -i '$ s/,$/\n    }\n  ]\n}/' "$list_i.json"

    # 清理临时目录
    rm -r "$list_i"

    # 编译
    ./sing-box rule-set compile "$list_i.json" -o "$list_i.srs"
done
