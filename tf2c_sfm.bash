#!/bin/bash
# tf2c_sfm.bash
# Install/Update SFM files for TF2/Classic
#
# USE AT YOUR OWN RISK! NO WARRANTY!
#
clear
function query(){
	echo -n '> ' 1>&2
	read -r answer
	echo "$answer"
}

function getdir(){
	for i in ${STEAM_DIRS[@]}
	do
		dir="${i}/steamapps/common/${1}"
		test -d "$dir" && echo "$dir" && return
		dir="${i}/steamapps/sourcemods/${1}"
		test -d "$dir" && echo "$dir" && return
	done
	echo "Could not find a ${1} installation." 1>&2
	exit 1
}
function vpk_extract(){
	# LD_LIBRARY_PATH="${DIR_VPK_LIB}:${LD_LIBRARY_PATH}" "$VPK_LINUX" "$@"
	"$VPK" -x "$2" -re '^(maps|materials|models|sound|particles)/' "$1"
}
function vpk_size(){
	for i in "$@"
	do
		"$VPK" -la -re '^(maps|materials|models|sound|particles)/' "$i"
	done |
	awk -F: '
		{size += $NF}
		END{print int(size/1000/1000/1000)+1}
	'
}
vpk_confirm(){
	echo This requires "$(vpk_size "$@")"GB of free space.
	echo
	echo 'Do you want to continue? [y/n]'
	case "$(query)" in
	[yY]*)	echo Sit back, this can take a few minutes...
		sleep 3 ;;
	*)	echo Aborting...
		exit ;;
	esac
}
function fixmat(){
	# TF2C uses vmt shaders with the format SDK_xyz
	# SFM only understands xyz
	find "$1" -type f -iname '*.vmt' |
	while read -r i
	do
		if sed -i '1s,^"SDK_,",g' "$i"
		then
			echo Fixed "$i"
		else
			echo Could not fix "$i"
		fi
	done
}

STEAM="$HOME/.steam/debian-installation"
while ! test -d "$STEAM"
do
	echo
	echo 'Could not find Steam installation.'
	echo 'Where is Steam installed on your system?'
	STEAM="$(query)"
done

# steam game folders
STEAM_DIRS=($(sed -nE '/path/s,^.*[ 	]"([^"][^"]*)"$,\1,gp' "${STEAM}/config/libraryfolders.vdf"))

# Valve's vpk_linux32 does not work currently
#for i in ${STEAM_DIRS[@]}
#do
#	VPK_LINUX="$(find "$i" -type f -iname 'vpk_linux32' -print |sed 1q)"
#	test -n "$VPK_LINUX" && break
#done
#if test -z "$VPK_LINUX"
#then
#	echo 'Could not find a vpk_linux32 installation.'
#	exit 1
#fi
#DIR_VPK_LIB="$(dirname "$VPK_LINUX")"

VPK="$(which vpk)"
test -z "$VPK" && VPK="${HOME}/.local/bin/vpk"
if ! test -x "$VPK"
then
	echo 'Could not find vpk installation.'
	echo 'To install: pipx install vpk'
	exit 1
fi

DIR_SFM="$(getdir SourceFilmmaker)"
DIR_TF2C="$(getdir tf2classic)"
DIR_SFM_TF2C="${DIR_SFM}/game/tf2classic"

echo '------------------------'
echo SourceFilmmaker: $DIR_SFM
echo TF2C: $DIR_TF2C
echo VPK: $VPK
echo '------------------------'
echo
echo
echo 'What would you like to do?'
echo '1 - Install/Update TF2Classic SFM content'
echo '2 - Update TF2 SFM content'
echo '3 - Fix TF2Classic SFM installation'
case "$(query)" in
1)
	if ! test -d "$DIR_SFM_TF2C"
	then
		if ! mkdir "$DIR_SFM_TF2C"
		then
			echo "Could not create ${DIR_SFM_TF2C}."
			exit 1
		fi
	else
		echo Updating "$DIR_SFM_TF2C" will override files.
	fi
	vpk_confirm "${DIR_TF2C}/vpks/tf2c_assets_dir.vpk"
	vpk_extract "${DIR_TF2C}/vpks/tf2c_assets_dir.vpk" "$DIR_SFM_TF2C"
	fixmat "$DIR_SFM_TF2C"
	;;
2)
	DIR_TF="$(getdir 'Team Fortress 2')"
	echo TF2: $DIR_TF
	echo
	echo Updating "${DIR_SFM}/game/tf" will override files.
	vpk_confirm "${DIR_TF}/tf/tf2_textures_dir.vpk" "${DIR_TF}/tf/tf2_misc_dir.vpk" "${DIR_TF}/tf/tf2_sound_misc_dir.vpk"
	for i in sound_misc misc textures
	do
		vpk_extract "${DIR_TF}/tf/tf2_${i}_dir.vpk" "${DIR_SFM}/game/tf"
	done
	echo
	echo 'All done!'
	exit
	;;
3)
	fixmat "$DIR_SFM_TF2C"
	;;
*)	echo Aborting...
	exit ;;
esac

echo
echo 'All done!'
echo Launch the SFM SDK and make sure the tf2classic searth path is enabled.
