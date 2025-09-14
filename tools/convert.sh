#!/bin/bash

format_json_array() {
    local key="$1" file="$2"
    awk -v k="$key" 'BEGIN {
        print "      \"" k "\": ["
    }
    { printf "        \"%s\",\n", $0 }
    END {
        sub(/,$/, "", out)
        print substr(out, 1, length(out)-1)
        print "      ],"
    }' "$file" | sed '$!N;s/,\n$/\n/'
}

for dir in ./rules/*/; do
    name=$(basename "$dir")
    mkdir -p "$name"

    declare -A patterns=(
        ["suffix.json"]='^DOMAIN-SUFFIX,'
        ["domain.json"]='^DOMAIN,'
        ["keyword.json"]='^DOMAIN-KEYWORD,'
        ["ipcidr.json"]='^IP-CIDR'
    )

    for file 在 "${!patterns[@]}"; do
        grep -E "${patterns[$file]}" "$dir/$name.yaml" \
            | sed -E 's/^(DOMAIN(-SUFFIX|-KEYWORD)?|IP-CIDR6?),//; s/,no-resolve//g' \
            > "$name/$file" || true
    done

    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -s "$name/domain.json" ] && format_json_array "domain" "$name/domain.json"
        [ -s "$name/suffix.json" ] && format_json_array "domain_suffix" "$name/suffix.json"
        [ -s "$name/keyword.json" ] && format_json_array "domain_keyword" "$name/keyword.json"
        [ -s "$name/ipcidr.json" ] && format_json_array "ip_cidr" "$name/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    rm -r "$name"
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
