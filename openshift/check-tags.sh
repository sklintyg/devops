#!/bin/bash


FMT="%-30s%-10s%-100s\n"
SORT_ARGS="-n -t . -k 4"
KEEP=1
images=(
  'intygstjanst:3.12.0,3.13.0,3.14.0'
  'logsender:6.7.0,6.8.0,6.9.0'
  'minaintyg:3.13.0,3.14.0,3.15.0'
  'webcert:6.7.0,6.7.1,6.8.0,6.9.0'
  'rehabstod:1.13.0,1.13.1,1.14.0,1.15.0'
  'privatlakarportal:1.14.0,1.15.0,1.16.0'
  'statistik:7.6.0,7.7.0,7.8.0'
  'srs:1.4.0'
  'intygsadmin:1.3.0,1.4.0,1.5.0'
)

suffix=('' '-artifact' '-verified')

function allTags {
  tags=($(echo $(oc get is $1 --template='{{range .status.tags}}{{.tag}}{{"\n"}}{{end}}' | sort $SORT_ARGS)))
  printf $FMT "$1" "" "${tags[*]}"
}

function allVersionedTags {

  readarray -td, verarr < <(printf '%s' "$2")

  for j in "${verarr[@]}"; do
    tags=($(echo $(oc get is $1 --template='{{range .status.tags}}{{.tag}}{{"\n"}}{{end}}' | grep ^${j} | sort $SORT_ARGS)))
    printf $FMT "$1" "$j" "${tags[*]}"
  done
}

function tagsToDelete {

  readarray -td, verarr < <(printf '%s' "$2")

  for j in "${verarr[@]}"; do
    tags=($(echo $(oc get is $1 --template='{{range .status.tags}}{{.tag}}{{"\n"}}{{end}}' | grep ^${j} | sort $SORT_ARGS)))
    n_tags=${#tags[@]}

    if [ ${n_tags} -gt ${KEEP} ]; then
      n_rem=$((${n_tags} - ${KEEP}))
      for tag in ${tags[*]}; do
        printf $FMT "$1" "$j" "${tag}"
        n_rem=$((${n_rem} - 1))
        [ ${n_rem} -eq 0 ] && break
      done
    fi
  done
}

for i in "${images[@]}"; do
  readarray -td: imgarr < <(printf '%s' "$i")

  for j in "${suffix[@]}"; do
    IS_NAME="${imgarr[0]}$j"
    IS_VERSIONS="${imgarr[1]}"

    case $1 in

      1)
        allTags $IS_NAME
        ;;

      2)
        allVersionedTags $IS_NAME $IS_VERSIONS
        ;;

      3)
        tagsToDelete $IS_NAME $IS_VERSIONS
        ;;

      *)
        echo -n "unknown "
        ;;
    esac
  done
done
