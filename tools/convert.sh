#!/bin/bash
# 处理文件
for dir 在 ./rules/*; do
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

    # 处理文件内容并加上 JSON 键
    for k in domain suffix keyword ipcidr; do
        file="$name/$k.json"
        if [ -s "$file" ]; then
            sed -i 's/^/        "/;s/$/",/' "$file"
            sed -i "1s/^/      \"${json_keys[$k]}\": [\n/" "$file"
            sed -i '$ s/,$/\n      ],/' "$file"
        else
            rm -f "$file"
        fi
    done

    # 合并 JSON 文件
    cat > "$name.json" <<EOF
{
  "version": 2,
  "rules": [
    {
EOF

    for k in domain suffix keyword ipcidr; do
        [ -f "$name/$k.json" ] && cat "$name/$k.json" >> "$name.json"
    done

    # 结尾修复
    sed -i '$ s/,$/\n    }\n  ]\n}/' "$name.json"

    # 清理临时文件
    rm -r "$name"

    # 编译 srs 文件
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
