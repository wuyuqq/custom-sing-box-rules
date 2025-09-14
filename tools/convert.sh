#!/bin/bash
set -e

for rule in ./rules/*; do
    name=$(basename "$rule")
    mkdir -p "$name"

    awk -F, '/^DOMAIN-SUFFIX,/ {print $2}' "$rule/$name.yaml" > "$name/suffix.json"
    awk -F, '/^DOMAIN,/ {print $2}' "$rule/$name.yaml" > "$name/domain.json"
    awk -F, '/^DOMAIN-KEYWORD,/ {print $2}' "$rule/$name.yaml" > "$name/keyword.json"
    awk -F, '/^IP-CIDR/ {gsub(/,no-resolve/,""); gsub(/^IP-CIDR6?/,""); print $2}' "$rule/$name.yaml" > "$name/ipcidr.json"

    json_wrap() {
        local file="$1"
        local key="$2"
        [ -f "$file" ] || return
        awk -v k="$key" 'BEGIN{print "      \""k"\": ["}
            {lines[NR]=$0}
            END{
                for(i=1;i<=NR;i++){
                    if(i<NR) print "        \"" lines[i] "\","
                    else print "        \"" lines[i] "\""
                }
                print "      ],"
            }' "$file"
    }

    {
        echo "{"
        echo "  \"version\": 2,"
        echo "  \"rules\": ["
        echo "    {"
        json_wrap "$name/domain.json" "domain"
        json_wrap "$name/suffix.json" "domain_suffix"
        json_wrap "$name/keyword.json" "domain_keyword"
        json_wrap "$name/ipcidr.json" "ip_cidr"
        echo "    }"
        echo "  ]"
        echo "}"
    } > "$name.json"

    [ -d "$name" ] && rm -r "$name"

    ./sing-box rule-set compile "$name.json" -o "$name.srs"
done
