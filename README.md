# Getting offline information from wikidata to populate popups in Lifemap

## Get the wikpedia information and generate the json files  and download associated images

Split the data in sets  of 10 000 taxons

    python ../split.py ../TreeFeatures2.json  > tax2spec.eukar
    split -l 10000 tax2spec.eukar split_

Generate a script

    for file in `ls split*`
    do
    echo $file
    echo "../get_wiki_info_curl.sh $file $file.json &> $file.log & " >> lance_job.sh
    echo "sleep 5" >> lance_job.sh
    done

Script looks like:

    ../get_wiki_info_curl.sh split_aa split_aa.json &> split_aa.log & 
    sleep 5
    .
    .
    .
    ../get_wiki_info_curl.sh split_ft split_ft.json &> split_ft.log & 
    sleep 5

Finally slit the script in to blocks of scripts of 20 jobs  (20 seems to be the max number of connections) and launch them one by one


## How to tar all the images:

The is to many images to use the wildcard * for selecting images

    grep "\"name\""   split_*.json  | awk '{print $3}'|cut -f1 -d","|sed -e "s/^\"//" |sed -e "s/\"$//" > List_images
    tar -cf ../new_tar/eukar_image.tar  -T List_images
