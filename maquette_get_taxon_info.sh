#!/bin/bash

# Fonction d'encodage
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
resume="resume.html"
outjson="resume.json"
touch $resume
rm $resume
touch $outjson
rm $outjson
n=0 #nb de de taxon
ninfo=0  #nb de de taxon avec info
nimage=0  #nb de de taxon avec image
cat   TreeFeatures2.json | jq -c '.[] | {sci_name: .sci_name , taxid: .taxid}' | while read json ; do
	i=$(echo $json | jq -r .sci_name)
  tid=$(echo $json | jq -r .taxid)
	n=$((n+1))
	echo " Traitement de $i (Taxon ID $tid)"
  echo "# taxons = $n, # infos = $ninfo, # images = $nimage"
	echo "<h1>$i</h1>" >> $resume
  toto=`mktemp`
  if [[ ! -f $toto ]]
  then
    echo "Erreur pendant la creation du fichier temporaire"
    exit 1
  fi
	encoded=$( rawurlencode "$i" )
	wget -q  -O   $toto "https://fr.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&titles=$encoded&redirects&exintro&piprop=original|thumbnail|name&pithumbsize=400&format=json"
	# Verifie si l'info existe
	miss=`cat $toto |jq '.query.pages[].missing'`
	if [ $miss == '""' ]
	then
		echo "Pas de données"
		echo "Pas de données" >> $resume
	else
		ninfo=$((ninfo+1))
		# Recupere l'image
		#url=`cat toto |jq '.query.pages[].original.source' |sed -e 's/"//g'`
		url=`cat $toto |jq '.query.pages[].thumbnail.source' |sed -e 's/"//g'`
		# Recupere le nom  de l'image
		image_name=`basename $url`
		echo $url
		if [ $url  == null ]
		then
			echo "Pas d'image"
      desc=`cat $toto |jq '.query.pages[].extract'`
      echo $desc >> $resume
		else
			nimage=$((nimage+1))
			echo "Nom de l'image = $image_name"
			# if [ -f $image_name ]
			# then
			# 	rm $image_name
			# fi
			# Recupere l'image
			wget  -q $url
			# Recupere l'info sur l'image
      image_info=`mktemp`
      if [[ ! -f $image_info ]]
      then
        echo "Erreur pendant la creation du fichier temporaire"
        exit 1
      fi
			wget -q  -O   $image_info "https://www.mediawiki.org/w/api.php?action=query&titles=File:$image_name&prop=imageinfo&iiprop=extmetadata&format=json"
			# Recupere le texte
      desc=`cat $toto |jq '.query.pages[].extract'`
      echo $desc >> $resume
			# Ajoute l'image
			echo "<br><img src=$image_name width = 200px><br>">> $resume
			# Ajoute l'info sur l'image
			echo "<h2>Image info :</h2>" >> $resume
			cat $image_info >> $resume
      #imgdesc=`cat $image_info|jq '.query.pages[].extract
      imgdesc=`cat $image_info |jq '.query.pages[].imageinfo'`


      if [ $imgdesc == null ]
      then
        artist="unknown"
        credit="unknown"
        licence="unknow"
        copyrighted="unknown"
        usage="unknown"
      else
        artist=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Artist.value'`
        credit=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Credit.value'`
        licence=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.LicenseShortName.value'`
        copyrighted=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.Copyrighted.value'`
        usage=`cat $image_info |jq '.query.pages[].imageinfo[].extmetadata.UsageTerms.value'`
      fi
      echo "effacer $image_info"
      rm $image_info
      # Ecrit le json
      # {
      #      "sciname": "mus musculus",
      #     "taxid": "2888222",
      #     "desc": "tretf  fdjdsnfdsfds",
      #     "image" {
      #             "name": "Mouse.jpg",
      #             "copyright": "",
      #             "licence": "";
      #             "credit": "",
      #             "artist": ""
      #             }
      #   }
      jo -p sciname=$i taxid=$tid desc=$desc img=$(jo name=$image_name licence=$licence credit=$credit artist=$artist copyrighted=$copyrighted usage=$usage) >>  $outjson
      #jo -p sciname=$i taxid=$tid desc=$desc img=$(jo name="ll") >>  $outjson

    fi
	fi
  echo "effacer $toto"
  rm $toto
done
