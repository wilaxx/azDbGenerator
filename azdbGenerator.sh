#!/bin/bash

alphabet=('e');

startup() {
  js_obj_file="$HOME/db_songs_azlyrics.js";
  touch $js_obj_file;
  tempname=`basename $0 .sh`;
  tempdir="/tmp/$tempname";
  if [[ ! -e $tempdir ]]; then
    mkdir -p $tempdir;
  fi
};

curl_alphabet() {
  tempfile=$tempdir/$i.html;
  touch $tempfile;
  url="https://www.azlyrics.com/$i.html";
  user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36';

  curl -A "$user_agent" --url "$url" > ${tempfile};
  if [[  "$?" == "0" ]]; then
    return 0;
  else
    echo "erreur sur le curl";
    return 1;
  fi   
}
keepArtistsTags() {
    while read -r line; do     
      echo $line | grep -e '<a href="' | grep -e '</a>' | grep -e '<br>' >> ${tempdir}/${i}_artists;
    done <${tempfile}
}
keepArtistInfos() {
    
  while read -r lino; do
    artist="";
    url_temp="";
    url_part=`echo $lino | grep -o -P '(?<=\").*(?=\")'`;
    echo "new2 url_part vaut : $url_part";
    echo $lino > "$tempdir/tempart";
    echo "lino vaut : $lino";
    url_temp="https://www.azlyrics.com/$url_part";
    echo "url_temp vaut : $url_temp";
    artist=`sed -e 's/<[^>]*>//g' $tempdir/tempart`;
    echo "artist vaut : $artist";
    curl_artist_url;
    # filter_tags;
    # remove_html;
    # filter_albums;
    # sorting_songs;
  done <"${tempdir}/${i}_artists"
}


curl_artist_url() {
  user_agent='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36';
  curl -A "$user_agent" --url "$url_temp" > ${tempdir}/url.tmp;
  echo "tempdir/url.tmp vaut : ";
  cat $tempdir/url.tmp;
  if [[ "$?" == 0 ]]; then
    return 0;
  else
    echo "erreur sur le curl";
    # cleanup;
    return 1;
  fi   
}
filter_tags() {
  while read -r line; do     
    echo $line | grep -e '^<' | grep -e 'class="album"' -e 'class="listalbum-item"><a' >> ${tempdir}/lyrics.html;
  done <"${tempdir}/url.tmp"
}
remove_html() {
  sed -i 's/<[^>]*>//g' ${tempdir}/lyrics.html
}
filter_albums() {
  while read -r line; do     
    echo $line | grep -e '^<' | grep -e 'class="album"' -e 'class="listalbum-item"><a' >> ${tempdir}/lyrics.tmp
  done <"${tempdir}/lyrics.html"
}
sorting_songs() {
  c_album="";
  while read -r line; do
  
  echo "$line" | grep -o -P '(?<=.[^\"])+\".*\"(?=.)' > ${tempdir}/album.tmp;
    if [[ "$?" == "0" ]]; then
      c_album=`cat $tempdir/album.tmp`;
    else
      echo "{
      name: \"$line\",
      album: "$c_album",
      artist: "$artist"
    },
    " >> ${js_obj_file};
  fi
    done <"${tempdir}/lyrics.tmp"
};

####### Launching actions #######


startup;
for i in "${alphabet[@]}"; do
  curl_alphabet;
  keepArtistsTags;
  if [[ "$?" == "0" ]]; then
    echo "
    
    Le keepArtistsTags s est bien passe
    
    ";

  fi
  keepArtistInfos;
done

