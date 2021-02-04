#!/bin/bash
set -euo pipefail
LC_ALL=C
OLD_IFS=$IFS
IFS=$'\n'
resume="resume.html"
touch $resume
rm $resume
n=0 #nb de de taxon
ninfo=0  #nb de de taxon avec info
nimage=0  #nb de de taxon avec image
cat   TreeFeatures1.json | jq -c '.[] | {sci_name: .sci_name}' | while read json ; do
	i=$(echo $json | jq -r .sci_name)
	n=$((n+1))
	echo " Traitement de $i"
	echo "<h1>$i</h1>" >> $resume
	touch toto
	rm toto
	wget -q  -O   toto "https://fr.wikipedia.org/w/api.php?action=query&prop=extracts|pageimages&titles=$i&redirects&exintro&piprop=original|thumbnail|name&pithumbsize=400&format=json"
	# Verifie si l'info existe
	miss=`cat toto |jq '.query.pages[].missing'`
	if [ $miss == '""' ]
	then
		echo "Pas de données"
		echo "Pas de données" >> $resume
	else
		ninfo=$((ninfo+1))
		# Recupere l'image
		#url=`cat toto |jq '.query.pages[].original.source' |sed -e 's/"//g'`
		url=`cat toto |jq '.query.pages[].thumbnail.source' |sed -e 's/"//g'`
		# Recupere le nom  de l'image
		image_name=`basename $url`
		echo $url
		if [ $url  == null ]
		then
			echo "Pas d'image"
			cat toto |jq '.query.pages[].extract' >> $resume
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
			touch image_info
			rm image_info
			wget -q  -O   image_info "https://www.mediawiki.org/w/api.php?action=query&titles=File:$image_name&prop=imageinfo&iiprop=extmetadata&format=json"
			# Recupere le texte
			cat toto |jq '.query.pages[].extract' >> $resume
			# Ajoute l'image
			echo "<br><img src=$image_name width = 200px><br>">> $resume
			# Ajoute l'info sur l'image
			echo "<h2>Image info :</h2>" >> $resume
			cat image_info >> $resume
		fi
	fi
done
echo "Nombre de taxon             : $n"
echo "Nombre de taxon avec info   : $ninfo"
echo "Nombre de taxon avec image   : $nimage"
