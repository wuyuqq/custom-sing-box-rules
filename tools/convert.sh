#!/bin/bash
list=($(ls ./rules/))

for ((i = 0; i < ${#list[@]}; i++)); do
    mkdir -p "${list[i]}"

    # 规则提取映射：yaml关键字 -> 输出文件名:json_key
    declare -A rules_map=(
        ["DOMAIN,"]="${list[i]}/domain.json:domain"
        ["DOMAIN-SUFFIX,"]="${list[i]}/suffix.json:domain_suffix"
        ["DOMAIN-KEYWORD,"]="${list[i]}/keyword.json:domain_keyword"
        ["IP-CIDR"]="${list[i]}/ipcidr.json:ip_cidr"
        ["IP-CIDR6"]="${list[i]}/ipcidr.json:ip_cidr"
    )

    # 按需提取规则（注意这里使用的是英文 in）
    for key 在 "${!rules_map[@]}"; do
        file=${rules_map[$key]%:*}
        # 初始化目标文件（覆盖，防止旧数据残留）
        : > "$file"
        # 提取匹配行并去掉前缀（去掉 ,no-resolve）
        if grep -q "$key" "./rules/${list[i]}/${list[i]}.yaml"; then
            grep "$key" "./rules/${list[i]}/${list[i]}.yaml" \
                | sed "s/^$key//g" \
                | sed 's/,no-resolve//g' \
                >> "$file"
        fi
    done

    # 转 JSON 数组（按你原来的格式）
    for k 在 domain suffix keyword ipcidr; do
        file="${list[i]}/$k.json"
        case $k 在
            domain) json_key="domain" ;;
            suffix) json_key="domain_suffix" ;;
            keyword) json_key="domain_keyword" ;;
            ipcidr) json_key="ip_cidr" ;;
        esac

        if [ -f "$file" ]; then
            sed -i 's/^/        "/g' "$file"
            sed -i 's/$/",/g' "$file"
            sed -i "1s/^/      \"${json_key}\": [\n/g" "$file"
            sed -i '$ s/,$/\n      ],/g' "$file"
        fi
    done

    # 初始化 json 文件头
    json_file="${list[i]}.json"
    [ -f "$json_file" ] && rm -f "$json_file"
    {
        echo "{"
        echo "  \"version\": 1,"
        echo "  \"rules\": ["
        echo "    {"
    } > "$json_file"

    # 按固定顺序合并片段：domain -> suffix -> keyword -> ipcidr
    [ -f "${list[i]}/domain.json" ] && cat "${list[i]}/domain.json" >> "$json_file"
    [ -f "${list[i]}/suffix.json" ] && cat "${list[i]}/suffix.json" >> "$json_file"
    [ -f "${list[i]}/keyword.json" ] && cat "${list[i]}/keyword.json" >> "$json_file"
    [ -f "${list[i]}/ipcidr.json" ] && cat "${list[i]}/ipcidr.json" >> "$json_file"

    # 闭合 JSON（去掉最后多余逗号并闭合对象/数组）
    sed -i '$ s/,$/\n    }\n  ]\n}/g' "$json_file"

    # 清理并编译
    rm -r "${list[i]}"
    ./sing-box rule-set compile "$json_file" -o "${list[i]}.srs"
done
