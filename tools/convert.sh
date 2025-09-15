#!/bin/bash
for dir in ./rules/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")

    declare -A json_keys=( [domain]="domain" [suffix]="domain_suffix" [keyword]="domain_keyword" [ipcidr]="ip_cidr" )

    declare -A tmp_files
    for k in domain suffix keyword ipcidr; do
        case $k in
            domain) pattern='DOMAIN,' ;;
            suffix) pattern='DOMAIN-SUFFIX,' ;;
            keyword) pattern='DOMAIN-KEYWORD,' ;;
            ipcidr) pattern='IP-CIDR' ;;
        esac
        tmp=$(grep "$pattern" "$dir/$name.yaml")
        [ -n "$tmp" ] && {
            if [ "$k" == "ipcidr" ]; then
                tmp=$(echo "$tmp" | sed 's/^IP-CIDR,//;s/^IP-CIDR6,//;s/,no-resolve//')
            else
                tmp=$(echo "$tmp" | sed "s/^$pattern//")
            fi
            tmp_files[$k]="$tmp"
        }
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

    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
