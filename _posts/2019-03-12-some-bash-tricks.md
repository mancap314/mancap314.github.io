---
layout: post
comments: true
author: Manuel Capel
title: Some Bash Tricks
date: 2019-03-12
categories: [programming]
---
To open this blog, a few *bash* tricks used to manage it, that could be useful by occasion on many other cases. This blog is runned with [jekyll](https://jekyllrb.com/), and I created some scripts to create posts, and create/remove categories (tags) associated to posts.

## Iterate through properties in files
Each category is associated with a file in the `_category` folder. In each of those files, there is a line starting with `category: ` followed by the category (name). We want to retrieve the file name and the category name it contains:

```bash
categories=()
category_files=()
for filename in ../_category/*; do
  if [ -f "${filename}" ]; then
    category_name=$( grep -m 1  '^category: ' ${filename} \
        | sed "s/^category: //g" | sed "s/ /-/g" )
    categories+=( ${category_name} )
    category_files+=( ${filename} )
  fi
done
```
On l.1-2 we initialize the array that will contain the category names and the files they are in. On l.3 we iterate through the files in the `_category` folder (and check for each one if it's actually a file in the following line). The real trick is on l.5. There are 3 commands piped with another inside `$( )`:
1. `grep -m 1  '^category: ' ${filename}`: Take the first line in the file starting with `category`
2. `sed "s/^category: //g"`: Remove `category: ` at the beginning of the line, resp. replace it with empty string.
3. `sed "s/ /-/g`: Replace spaces by `-` (otherwise it confuses the array)
The following lines just append the extracted data to the lists and close the loop.

## Check a user entry
When a user wants to remove a category, the categories are listed with an associated number:
```
-first category [0]
-category 2 [1]
- etc.
```

There are 3 constraints for the user entry:
1. it must be a number (an integer)
2. it must be larger or equal 0
3. it must be less or equal the number of categories

This is handled in l.4 of the following snippet:
```bash
article_categories=()
while true; do
  read entry
  if [[ "$entry" =~ ^[0-9]+$ ]] \
        && [[ "$(( entry ))" -ge 0 ]] \
        && [[ "$(( entry ))" -lt ${#categories[@]} ]]; then
    category_to_remove=${categories[$(( entry ))]}
    file_to_remove=${category_files[$(( entry ))]}
    break;
  else
    echo "invalid entry: must be an integer \
            between 0 and $(( ${#categories[@]} - 1 ))"
  fi
done
```
The first condition in `if` checks by regular expression that `$entry` has the form of an integer (must be done, since also letters can be interpreted as numbers). The second checks the second contraint, same for the third.

## Checking and transforming strings
When a user enters a name for a category, this name is processed to generate `category_name`, `title_name` and `file_name`

```bash
read name
category_name=$( echo ${name} \
    | sed 's/[^a-zA-Z0-9 ]\+/-/g' \
    | sed 's/[ ]\+/ /g' \
    | sed 's/[ ]\+-//g' )
title_name=$( echo ${category_name} \
    | sed 's/[ ]\+/-/g' \
    | tr [:upper:] [:lower:]  )
file_name=$( echo ${title_name} \
    | iconv -f utf8 -t ascii//TRANSLIT//IGNORE )
if [[ -z $( echo ${title_name} | tr -d '-' ) ]]; then
  echo "category name must contain at least \
        one alphanumerical character, \
        please enter another name:"
```
On l.2 we have `sed 's/[^a-zA-Z0-9 ]\+/-/g'` replacing all non-alphanumerical characters by `-`, followed by `sed 's/[ ]\+/ /g'` replacing all multiple spaces by single spaces, itself followed by `sed 's/[ ]\+-//g'` removing `-` (and the spaces before) as it can occur at the end of the string. For example, `Ca&tegory   name` would be transformed in `Category name`.

On l.3 the spaces are replaced by `-` and the letter in upper case by lower cases. `Category name` gets `category-name`. And on l.4, the result of the previous transformation is formatted to be compatible with a file name (format conversion).

If the entered category name was empty or contained just non-alphanumerical characters, then `$title_name` is empty or contains just `-` characters, and the user has to enter another name.

## Check if a date is in the valid format
When a user creates an article, the default date is today. However s/he can enter another date if wished, but this date has to be in the format 'YYYY-MM-DD'. The trick here is to try to transform the entry to a date in this format, and if it fails, it means the entry was not in the right format:

```bash
default_date=$(date +"%Y-%m-%d")
article_date=$default_date
while true; do
  echo Enter date \(default: ${default_date}\):
  read line
  if [ ! -z "$line" ]; then
    if date -d "$line" +"%Y-%m-%d" > /dev/null 2>&1; then
      article_date=$( date -d "$line" +"%Y-%m-%d" )
      break
    else
      echo invalid date format
    fi
  else
    break
  fi
done
```
On l.1-2, the default date (today) is created, and assigned per default to the article date. If the user entered an non-empty string (l.6), then we try to transform it to a date of the expected format (l.7). If this successes, the entry (formatted) is assigned to the article date.


The complete scripts are available in a [Github repo folder](https://github.com/mancap314/mancap314.github.io/tree/master/scripts). Hope it has been useful for you, and if you have any question, don't hesitate to ask.
