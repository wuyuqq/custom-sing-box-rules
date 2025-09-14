#!/bin/bash
set -e

for rule in ./rules/*; do
    name=$(basename "$rule")
    mkdir -p "$name"

    # 归类
    if grep -q '^DOMAIN-SUFFIX,' "$rule/$name.yaml"; then
        grep '^DOMAIN-SUFFIX,' "$rule/$name.yaml" | sed 's/^DOMAIN-SUFFIX,//' > "$name/suffix.json"
    fi
    if grep -q '^DOMAIN,' "$rule/$name.yaml"; then
        grep '^DOMAIN,' "$rule/$name.yaml" | sed 's/^DOMAIN,//' > "$name/domain.json"
    fi
    if grep -q '^DOMAIN-KEYWORD,' "$rule/$name.yaml"; then
        grep '^DOMAIN-KEYWORD,' "$rule/$name.yaml" | sed 's/^DOMAIN-KEYWORD,//' > "$name/keyword.json"
    fi
    if grep -q '^IP-CIDR' "$rule/$name.yaml"; then
        grep '^IP-CIDR' "$rule/$name.yaml" | sed 's/^IP-CIDR6\?\,//' | sed 's/,no-resolve//' > "$name/ipcidr.json"
    fi

    # 转成 json
    wrap_json() {
        local f=$1 key=$2
        [ -f "$f" ] || return
        sed -i 's/^/        "/' "$f"
        sed -i 's/$/",/' "$f"
        sed -i "1s/^/      \"$key\": [\n/" "$f"
        sed -i '$ s/,$/\n      ],/' "$f"
    }

    wrap_json "$name/domain.json" "domain"
    wrap_json "$name/suffix.json" "domain_suffix"
    wrap_json "$name/keyword.json" "domain_keyword"
    wrap_json "$name/ipcidr.json" "ip_cidr"

    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        [ -f "$name/domain.json" ] && cat "$name/domain.json"
        [ -f "$name/suffix.json" ] && cat "$name/suffix.json"
        [ -f "$name/keyword.json" ] && cat "$name/keyword.json"
        [ -f "$name/ipcidr.json" ] && cat "$name/ipcidr.json"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    rm -r "$name"
    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
