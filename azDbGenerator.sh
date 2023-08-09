#!/bin/bash

REGEXFILE="$DEVTOOLS/regexfile";
LYRICS_DIR="$HOME/azlyrics"

mkdir -p $LYRICS_DIR;

startup() {
  query="$i";
  queryword=`echo "${i,,}" | sed -r 's/\s+//g'`;
  tempname=`basename $0 .sh`;
  timestamp=`date +'%d%m%Y-%H%M%S'`;
  tempdir="/tmp/$tempname";
  tempfile="$tempdir/$queryword-$timestamp.html"
  lyricsfile=""
  if [[ ! -e $tempdir ]]; then
    mkdir -p $tempdir;
  fi
  touch $tempfile;
};

cleanup() {
  echo "Suppression du fichier : $tempfile";
  sleep 3;
  rm -rf $tempfile;
  return 0;
}

create_url() {
  query="$i";
  echo "query vaut $query";
  queryletter="${queryword:0:1}";

  if [[  "$queryletter" =~ [0-9] ]]; then
    url="https://www.azlyrics.com/19/$queryword.html";
    echo "url vaut : $url";
    return 0;
  elif [[ "$queryletter" =~ [a-z] ]]; then
    echo "La premiere lettre est une lettre"
    url="https://www.azlyrics.com/$queryletter/$queryword.html";
    echo "url vaut : $url";
    return 0;
  else
    echo "Artist name must start with letter or number"
    return 1;
  fi   
};

curl_url() {
  user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36';
  curl -A "$user_agent" --url "$url" > $tempfile;
  if [[  "$?" == "0" ]]; then
    return 0;
  else
    echo "erreur sur le curl";
    cleanup;
    return 1;
  fi   
}

filterTags() {
  while read -r line; do     
    echo $line | grep -e '^<' | grep -e 'class="album"' -e 'class="listalbum-item"><a' >> "$LYRICS_DIR/$queryword.txt"
  done <$tempfile
}

removeHTML() {
  sed -i 's/<[^>]*>//g' "$LYRICS_DIR/$queryword.txt"
}

sortingSongs() {
  c_album="";
  while read -r line; do
  
  echo "$line" | grep -o -P '(?<=.[^\"])+\".*\"(?=.)' > /tmp/testaz;
    if [[ "$?" == "0" ]]; then
      c_album="$(cat /tmp/testaz)";
    else
      echo "{
      name: \"$line\",
      album: "$c_album",
      artist: \"Keny Arkana\"
    },
    " >> $queryword.txt;
  fi
    done <"$LYRICS_DIR/$queryword.txt"
};


generate_lyrics() {
  startup;
  create_url "$i";
  if [[ "$?" == "0" ]];then
      curl_url "$i";
    else
    echo "erreur sur le curl";
    cleanup;
    return 1;
  fi   
  filterTags;
  removeHTML;
  sortingSongs;
}

#Lancement du programme
for i in "$@"
  do
    generate_lyrics "$i";
  done

exit 0;

# $1 parameter to lower case then removing whitespaces
# echo "${1,,}" | sed -r 's/\s+//g'
# or
# removing whitessapces in $1 parameter then to lower case
# echo $1 | sed -r 's/\s+//g' | tr '[:upper:]' '[:lower:]'