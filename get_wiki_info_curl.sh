#!/bin/bash

# Fonction d'encodage
useragent="Lifemap/1.1 (https://lbbe.univ-lyon1.fr/-Penel-Simon-.html; simon.penel@univ-lyon1.fr) UsedBaseLibrary/1.4"
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER)
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}
set -euo pipefail
LC_ALL=C
OLD_IFS=$IFS
IFS=$'\n'
if [[ $#  < 2 ]]
then
  echo "Utilisation:"
  echo "$0 input.json output.json"
  exit
fi
injson=$1
outjson=$2
touch $outjson
rm $outjson
nf=`wc -l $1`
echo "Nombre d'especes = $nf"
n=0 #nb de de taxon
ninfo=0  #nb de de taxon avec info
nimage=0  #nb de de taxon avec image
#cat   $injson | jq -c '.[] | {sci_name: .sci_name , taxid: .taxid}' | while read json ; do
while IFS= read -r line
  do
  echo "LINE = $line"
	i=$(echo $line|cut -f2)
  tid=$(echo $line|cut -f1)
	n=$((n+1))
	echo " Traitement de $i (Taxon ID $tid)"
  echo "# taxons = $n / $nf, # infos = $ninfo, # images = $nimage"
  toto=`mktemp`
  if [[ ! -f $toto ]]
  then
    echo "Erreur pendant la creation du fichier temporaire"
    exit 1
  fi
	encoded=$( rawurlencode "$i" )
  echo 	curl -A $useragent -o   $toto "https://fr.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&titles=$encoded&redirects&exintro&piprop=original|thumbnail|name&pithumbsize=400&format=json"
exit
	curl -A $useragent -o   $toto "https://fr.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&titles=$encoded&redirects&exintro&piprop=original|thumbnail|name&pithumbsize=400&format=json"
	# Verifie si l'info existe
	miss=`cat $toto |jq '.query.pages[].missing'`
	if [ $miss == '""' ]
	then
		echo "Pas de données"
	else
		ninfo=$((ninfo+1))
		# Recupere l'image thumbnail
		#url=`cat toto |jq '.query.pages[].original.source' |sed -e 's/"//g'`
		url=`cat $toto |jq '.query.pages[].thumbnail.source' |sed -e 's/"//g'`
		# Recupere le nom  de l'image
		image_name=`basename $url`
		echo $url
    original_url=`cat $toto |jq '.query.pages[].original.source' |sed -e 's/"//g'`
		if [ $url  == null ]
		then
      echo "Pas d'image sur la page francaise test page anglaise"
      vengl=`mktemp`
      if [[ ! -f $vengl ]]
      then
        echo "Erreur pendant la creation du fichier temporaire"
        exit 1
      fi
      curl -A $useragent  -o   $vengl "https://en.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&titles=$encoded&redirects&exintro&piprop=original|thumbnail|name&pithumbsize=400&format=json"
      url=`cat $vengl |jq '.query.pages[].thumbnail.source' |sed -e 's/"//g'`
      original_url=`cat $vengl |jq '.query.pages[].original.source' |sed -e 's/"//g'`
      # Recupere le nom  de l'image
      image_name=`basename $url`
      echo $url
    fi
    if [ $url  == null ]
		then


      echo "Pas d'image sur la page anglaise"


      desc=`cat $toto |jq '.query.pages[].extract'`
      jo -p sciname=$i taxid=$tid desc=$desc  >>  $outjson

		else
			nimage=$((nimage+1))
			echo "Nom de l'image = $image_name"
			# if [ -f $image_name ]
			# then
			# 	rm $image_name
			# fi
			# Recupere l'image
			curl -A $useragent -O  $url
			# Recupere l'info sur l'image (ici le thumb)
      image_info=`mktemp`
      if [[ ! -f $image_info ]]
      then
        echo "Erreur pendant la creation du fichier temporaire"
        exit 1
      fi
			curl  -A $useragent   -o   $image_info "https://www.mediawiki.org/w/api.php?action=query&titles=File:$image_name&prop=imageinfo&iiprop=extmetadata&format=json"
			# Recupere la description
      desc=`cat $toto |jq '.query.pages[].extract'`

      # Recupere la description de l'image
      # imgdesc=`cat $image_info |jq '.query.pages[].imageinfo'`
      artist="unknown"
      credit="unknown"
      licence="unknow"
      copyrighted="unknown"
      usage="unknown"

      # original_url=`cat $toto |jq '.query.pages[].original.source' |sed -e 's/"//g'`
      original_image_name=`basename $original_url`
      # On recupre la nouvelle info
      # rm $image_info
      curl  -A $useragent   -o   $image_info "https://www.mediawiki.org/w/api.php?action=query&titles=File:$original_image_name&prop=imageinfo&iiprop=extmetadata&format=json"

      # Recupere la description de l'image
      imgdesc=`cat $image_info |jq '.query.pages[].imageinfo'`
      echo " DEBUG TEST imgdesc"
      if [[ $imgdesc != null ]]
      then
        artist=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Artist.value'`
        credit=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Credit.value'`
        licence=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.LicenseShortName.value'`
        copyrighted=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Copyrighted.value'`
        usage=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.UsageTerms.value'`
      fi
      rm $image_info
      jo -p sciname=$i taxid=$tid desc=$desc img=$(jo name=$image_name licence=$licence credit=$credit artist=$artist copyrighted=$copyrighted usage=$usage) >>  $outjson
    fi
	fi
  rm $toto
done < $injson
echo "Termine"
echo "# taxons = $n / $nf, # infos = $ninfo, # images = $nimage"
