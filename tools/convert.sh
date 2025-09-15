#!/bin/bash
for dir in ./rules/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")

    # json key 映射
    declare -A json_keys=( [domain]="domain" [suffix]="domain_suffix" [keyword]="domain_keyword" [ipcidr]="ip_cidr" )

    # 归类并生成临时内容
    declare -A tmp_files
    for k in domain suffix keyword ipcidr; do
        case $k in
            domain) pattern='DOMAIN,'; file_ext='domain.json' ;;
            suffix) pattern='DOMAIN-SUFFIX,'; file_ext='suffix.json' ;;
            keyword) pattern='DOMAIN-KEYWORD,'; file_ext='keyword.json' ;;
            ipcidr) pattern='IP-CIDR'; file_ext='ipcidr.json' ;;
        esac
        tmp=$(grep "$pattern" "$dir/$name.yaml" | sed \
            -e "s/^DOMAIN-//" -e "s/^IP-CIDR6,//" -e "s/,no-resolve//")
        [ -n "$tmp" ] && tmp_files[$k]="$tmp"
    done

    # 生成 JSON 文件
    {
        echo "{"
        echo '  "version": 2,'
        echo '  "rules": ['
        echo '    {'
        for k in domain suffix keyword ipcidr; do
            [ -n "${tmp_files[$k]}" ] && {
                echo "      \"${json_keys[$k]}\": ["
                echo "${tmp_files[$k]}" | sed 's/^/        "/;s/$/",/' | sed '$ s/,$//'
                echo "      ],"
            }
        done
        echo '    }'
        echo '  ]'
        echo '}'
    } > "$name.json"

    # 编译 srs 文件
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
