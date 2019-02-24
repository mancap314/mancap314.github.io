#/bin/bash

# Script to delete a category 
# Just provide the name of the category as first parameter

cd ../_category/

categories=()
category_files=()
for filename in ../_category/*; do
  if [ -f "${filename}" ]; then
    category_name=$( grep -m 1  '^category: ' ${filename} | sed "s/^category: //g" | sed "s/ /-/g" )
    categories+=( ${category_name} )
    category_files+=( ${filename} )
  fi
done

echo Category to remove \(type number\):
for ((i = 0; i < ${#categories[@]}; i++)); do
  echo $( echo "${categories[$i]}" ["$i"] | sed "s/-/ /g" )
done

article_categories=()
while true; do
  read entry
  if [[ "$entry" =~ ^[0-9]+$ ]] && [[ "$(( entry ))" -ge 0 ]] && [[ "$(( entry ))" -lt ${#categories[@]} ]]; then
    category_to_remove=${categories[$(( entry ))]}
    file_to_remove=${category_files[$(( entry ))]}
    break; 
  else
    echo invalid entry: must be an integer between 0 and $(( ${#categories[@]} - 1 ))
  fi
done

rm ${file_to_remove}

cd ../_posts/

# Remove category from the first line starting with "categories:" in each post file
for filename in *; do
  if [ -f "${filename}" ]; then
    sed "0,/^categories:/s/[,]*[ ]*${category_to_remove}//" ${filename} > ${filename}_
    rm ${filename}
    mv ${filename}_ ${filename}
  fi
done

echo ${category_to_remove} property file removed, and removed from the posts containing it
