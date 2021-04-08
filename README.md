# Getting offline information from wikidata to populate popups in Lifemap

# Get the wikpedia infrmation and generate the json file  and dowvload associated images
Run 

# How to tar all the images:

    grep "\"name\""   split_*.json  | awk '{print $3}'|cut -f1 -d","|sed -e "s/^\"//" |sed -e "s/\"$//" > List_images
    tar -cf ../new_tar/eukar_image.tar  -T List_images
