#!/usr/bin/env sh
# surf_linkselect.sh:
#   Usage: curl somesite.com | surf_linkselect [SURFWINDOWID] [PROMPT]
#   Deps: xmllint, dmenu
#   Info:
#     Designed to be used w/ surf externalpipe patch. Enables keyboard-only
#     link selection via dmenu. Given HTML stdin, extracts links one per line
#     Selected link is normalized based on current URI and printed to STDOUT.
#     Pipe the result to a new surf or xprop _SURF_URI accordingly.
SURF_WINDOW="${1:-$(xprop -root | sed -n '/^_NET_ACTIVE_WINDOW/ s/.* //p')}"
DMENU_PROMPT="${2:-Link}"

function dump_links_with_titles() {
  awk '{
    input = $0;

    $0 = input;
    gsub("<[^>]*>", "");
    gsub(/[ ]+/, " ");
    gsub("&amp;", "\\&");
    gsub("&lt;", "<");
    gsub("&gt;", ">");
    $1 = $1;
    title = ($0 == "" ? "None" : $0);

    $0 = input;
    match($0, /\<[ ]*[aA][^>]* [hH][rR][eE][fF]=["]([^"]+)["]/, linkextract);
    $0 = linkextract[1];
    gsub(/^[ \t]+/,"");
    gsub(/[ \t]+$/,"");
    gsub("[ ]", "%20");
    link = $0;

    if (link != "") {
      print title ": " link;
    }
  }'
}

function link_normalize() {
  URI=$1
  awk -v uri=$URI '{
    gsub("&amp;", "\\&");

    if ($0 ~ /^https?:\/\//  || $0 ~ /^\/\/.+$/) {
      print $0;
    } else if ($0 ~/^#/) {
      gsub(/[#?][^#?]+/, "", uri);
      print uri $0;
    } else if ($0 ~/^\//) {
      split(uri, uri_parts, "/");
      print uri_parts[3] $0;
    } else {
      gsub(/[#][^#]+/, "", uri);
      uri_parts_size = split(uri, uri_parts, "/");
      delete uri_parts[uri_parts_size];
      for (v in uri_parts) {
        uri_pagestripped = uri_pagestripped uri_parts[v] "/"
      }
      print uri_pagestripped $0;
    }
  }'
}

function link_select() {
  tr '\n\r' ' ' |
    xmllint --html --xpath "//a" - |
    dump_links_with_titles |
    awk '!x[$0]++' |
    # sort | uniq
    dmenu -p "$DMENU_PROMPT" -l 10 -i -w $SURF_WINDOW |
    awk -F' ' '{print $NF}' |
    link_normalize $(xprop -id $SURF_WINDOW _SURF_URI | cut -d '"' -f 2)
}

link_select