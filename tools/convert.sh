# 处理文件
list=($(ls ./rules/))
for ((i = 0; i < ${#list[@]}; i++)); do
	mkdir -p ${list[i]}
	# 归类
	# domain
	if [ -n "$(cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN-SUFFIX,')" ]; then
		cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN-SUFFIX,' | sed 's/^DOMAIN-SUFFIX,//g' > ${list[i]}/suffix.json
	fi
	if [ -n "$(cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN,')" ]; then
		cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN,' | sed 's/^DOMAIN,//g' >> ${list[i]}/domain.json
	fi
	if [ -n "$(cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN-KEYWORD,')" ]; then
		cat ./rules/${list[i]}/${list[i]}.yaml | grep 'DOMAIN-KEYWORD,' | sed 's/^DOMAIN-KEYWORD,//g' > ${list[i]}/keyword.json
	fi
	# ipcidr
	if [ -n "$(cat ./rules/${list[i]}/${list[i]}.yaml | grep 'IP-CIDR')" ]; then
		cat ./rules/${list[i]}/${list[i]}.yaml | grep 'IP-CIDR' | sed 's/^IP-CIDR,//g' | sed 's/^IP-CIDR6,//g' | sed 's/,no-resolve//g' > ${list[i]}/ipcidr.json
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

	# 合并顺序：domain → suffix → keyword → ipcidr
	if [ "$(ls ${list[i]})" = "" ]; then
		sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/g' ${list[i]}.json
	elif [ -f "${list[i]}.json" ]; then
		sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/g' ${list[i]}.json
		sed -i '$ s/,$/\n    },\n    {/g' ${list[i]}.json
		[ -f "${list[i]}/domain.json" ] && cat ${list[i]}/domain.json >> ${list[i]}.json
		[ -f "${list[i]}/suffix.json" ] && cat ${list[i]}/suffix.json >> ${list[i]}.json
		[ -f "${list[i]}/keyword.json" ] && cat ${list[i]}/keyword.json >> ${list[i]}.json
		[ -f "${list[i]}/ipcidr.json" ] && cat ${list[i]}/ipcidr.json >> ${list[i]}.json
	else
		[ -f "${list[i]}/domain.json" ] && cat ${list[i]}/domain.json >> ${list[i]}.json
		[ -f "${list[i]}/suffix.json" ] && cat ${list[i]}/suffix.json >> ${list[i]}.json
		[ -f "${list[i]}/keyword.json" ] && cat ${list[i]}/keyword.json >> ${list[i]}.json
		[ -f "${list[i]}/ipcidr.json" ] && cat ${list[i]}/ipcidr.json >> ${list[i]}.json
		sed -i '1s/^/{\n  "version": 2,\n  "rules": [\n    {\n/g' ${list[i]}.json
	fi

	# 结尾修复
	sed -i '$ s/,$/\n    }\n  ]\n}/g' ${list[i]}.json

	# 清理
	rm -r ${list[i]}
	./sing-box rule-set compile ${list[i]}.json -o ${list[i]}.srs
done
