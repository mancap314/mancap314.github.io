#/bin/bash

# Script to delete a category 
# Just provide the name of the category as first parameter

cd ../_category/

name="${1,,}"  # convert first arg (category name) to lower case

if [ ! -f ${name}.md ] ; then
  echo Category \"${name}\" doesn\'t exist, exit
  exit 1
fi

rm ${name}.md

capitalized=${name^}  # capitalize first letter

cd ../_posts/

# Remove category from the first line starting with "categories:" in each post file
for filename in *; do
  if [ -f "${filename}" ]; then
    sed "0,/^categories:/s/[,]*[ ]*${capitalized}//" ${filename} > ${filename}_
    rm ${filename}
    mv ${filename}_ ${filename}
  fi
done
