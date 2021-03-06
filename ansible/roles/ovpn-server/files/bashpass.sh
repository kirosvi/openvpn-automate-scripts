#!/usr/bin/env bash

# GitHub https://github.com/joshuar/bashpass

#declare -a separators=( '-' '_' '!' '@' '&' '*' '+' '=' \
#    '~' '`' '#' '%' '^' '+' ' ' \
#    '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' )

declare -a separators=( '-' '_' '!' '*' '+' '=' '+' \
    '1' '2' '3' '4' '5' '6' '7' '8' '9' '0' )


bracketize=0
surround=0
replacevowels=0

# Function to replace vowels in a word with
# random punctuation marks
replace_vowels() {
    local _w=$1
    local _vsubs=( '$' '%' '#' '@' '&' '*' )
    for v in a e i o u; do
        v_caps=$(echo $v | tr '[:lower:]' '[:upper:]')
        s=$((RANDOM%${#_vsubs[*]}))
        _w=$(echo "$_w" | tr ["$v$v_caps"] "${_vsubs[s]}")
        unset s
    done
    echo "$_w"
}

# Function to surround a word with a random bracket
# pair
bracketize_word() {
    local _w=$1
    local start_brackets=( '(' '{' '[' '<' )
    local end_brackets=( ')' '}' ']' '>' )
    b=$((RANDOM%${#start_brackets[*]}))
    _w=${start_brackets[$b]}$_w${end_brackets[$b]}
    unset b
    echo "$_w"
}

# Function to surround a password (or a word) with
# random separator
surround() {
    local _p=$1
#    local s1=$((RANDOM%${#separators[*]}))
#    local s2=$((RANDOM%${#separators[*]}))
#    _p=${separators[s1]}$_p${separators[s2]}
#    unset s1 s2
    echo "$_p"
}


while getopts ":n:d:bsv" opt; do
    case $opt in
        n)
            if (( OPTARG > 0 )); then
                word_count=$OPTARG
            else
                echo "Argument to -${opt} should be an integer."
                exit -1
            fi
            ;;
        d)
            if [[ -r $OPTARG ]]; then
                dictionary_file=$OPTARG
            else
                echo "Argument to -${opt} should be the path to a readable file."
                exit -1
            fi
            ;;
        b)
            bracketize=1
            ;;
        s)
            surround=1
            ;;
        v)
            replacevowels=1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
  esac
done

# if no word list file was specified with -d, attempt to
# use a myspell dictionary file in the user's language
if [[ -z $dictionary_file ]] && [[ -n $LANG ]]; then
    dictionary_file=/usr/share/myspell/${LANG/%.*/}.dic
    if [[ ! -r $dictionary_file ]]; then
        echo "Was attempting to use words from ${dictionary_file}."
        echo "but this file does does not exist or cannot be read."
        echo
        echo "Try specifying a valid path to a file containg a list of words"
        echo "with the -d option."
        exit -1
    fi
fi

# Breakdown of grep expressions:
#  '^[[:alpha:]]{4,8}$' : only show lines with between 4 to 8 alphabetical characters
# Breakdown of sed expressions:
#  's/\/.*//g' : remove the trailing /blah where matched
words=($(grep -E '^[[:alpha:]]{4,8}$' "${dictionary_file}" | sed -e 's/\/.*//g' | shuf -n "${word_count:-3}"))

for word in "${words[@]}"; do
    orig_word=$word
    # Do manipulations based on command-line parameters
    (( replacevowels == 1 )) && word=$(replace_vowels "${word}")
    (( bracketize == 1 )) && word=$(bracketize_word "${word}")
    # If this word is not the last word in the password, add
    # a separator
    if [[ ${orig_word} != ${words[$((${#words[*]} - 1))]} ]]; then
        s=$((RANDOM%${#separators[*]}))
        word=$word${separators[s]}
        unset s
    fi
    password=$password$word
done

# If -s (surround) command-line option passed,
# surround the password with extra separators
(( surround == 1 )) && password=$(surround "${password}")

echo -n "${password}"
echo
unset password

exit 0
