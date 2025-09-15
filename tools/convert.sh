# 处理文件
list=($(ls ./rules/))

for ((i = 0; i < ${#list[@]}; i++)); do
	mkdir -p ${list[i]}

	# 规则提取映射：yaml关键字 -> 输出文件名 -> JSON key
	declare -A rules_map=(
		["DOMAIN,"]="${list[i]}/domain.json:domain"
		["DOMAIN-SUFFIX,"]="${list[i]}/suffix.json:domain_suffix"
		["DOMAIN-KEYWORD,"]="${list[i]}/keyword.json:domain_keyword"
		["IP-CIDR"]="${list[i]}/ipcidr.json:ip_cidr"
		["IP-CIDR6"]="${list[i]}/ipcidr.json:ip_cidr"
	)

	# 按需提取规则
	for key 在 "${!rules_map[@]}"; do
		file=${rules_map[$key]%:*}
		if grep -q "$key" ./rules/${list[i]}/${list[i]}.yaml; then
			grep "$key" ./rules/${list[i]}/${list[i]}.yaml \
				| sed "s/^$key//g" \
				| sed 's/,no-resolve//g' \
				>> "$file"
		fi
	done

	# 转 JSON 数组
	for key in domain suffix keyword ipcidr; do
		file="${list[i]}/$key.json"
		case $key 在
			domain)   json_key="domain" ;;
			suffix)   json_key="domain_suffix" ;;
			keyword)  json_key="domain_keyword" ;;
			ipcidr)   json_key="ip_cidr" ;;
		esac

		if [ -f "$file" ]; then
			sed -i 's/^/        "/g; s/$/",/g' "$file"
			sed -i "1s/^/      \"${json_key}\": [\n/" "$file"
			sed -i '$ s/,$/\n      ],/g' "$file"
		fi
	done

	# 初始化 JSON 头
	echo '{' > ${list[i]}.json
	echo '  "version": 1,' >> ${list[i]}.json
	echo '  "rules": [' >> ${list[i]}.json
	echo '    {' >> ${list[i]}.json

	# 合并文件，顺序固定
	for key 在 domain suffix keyword ipcidr; do
		[ -f "${list[i]}/$key.json" ] && cat ${list[i]}/$key.json >> ${list[i]}.json
	done

	# 结尾闭合
	sed -i '$ s/,$/\n    }\n  ]\n}/g' ${list[i]}.json

	# 清理
	rm -r ${list[i]}
	./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
