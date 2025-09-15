#!/bin/bash
# 处理文件
for dir 在 ./rules/*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")

    # json key 映射
    declare -A json_keys=( [domain]="domain" [suffix]="domain_suffix" [keyword]="domain_keyword" [ipcidr]="ip_cidr" )
    declare -A json_data

    # 归类并生成 JSON 内容
    for k 在 domain suffix keyword ipcidr; do
        case $k 在
            domain)        pattern='DOMAIN,';        ;;
            suffix)        pattern='DOMAIN-SUFFIX,'; ;;
            keyword)       pattern='DOMAIN-KEYWORD,';;
            ipcidr)        pattern='IP-CIDR';        ;;
        esac

        if grep -q "$pattern" "$dir/$name.yaml"; then
            if [ "$k" = "ipcidr" ]; 键，然后
                # IP-CIDR 特殊处理
                data=$(grep "$pattern" "$dir/$name.yaml" | sed 's/^IP-CIDR,//;s/^IP-CIDR6,//;s/,no-resolve//' | awk '{print "        \"" $0 "\","}')
            else
                data=$(grep "$pattern" "$dir/$name.yaml" | sed "s/^$pattern//" | awk '{print "        \"" $0 "\","}')
            fi
            # 去掉最后多余逗号
            data="${data%?}"
            json_data[$k]="      \"${json_keys[$k]}\": [\n$data\n      ],"
        fi
    done

    # 生成最终 JSON 文件
    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        for k in domain suffix keyword ipcidr; do
            [ -n "${json_data[$k]}" ] && echo "${json_data[$k]}"
        done
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    # 编译 srs 文件
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
