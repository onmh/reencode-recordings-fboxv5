#!/bin/bash

###############################################################################
# 21/10/2011 OH
# transcodage ffmpeg h264/mp3 en conteneur mp4
# pour fichiers source mpeg2/aac en conteneur ts (typiquement flux freebox)
# source (apres de nombreux essais infructueux...) :
# http://h264.code-shop.com/trac/wiki/Encoding
# le codec audio libfaac est remplacé par du mp3
# car il n'est pas dispo sur toutes les plate-formes
# mais si il est dispo, il faut remplacer :
# -acodec libmp3lame
# par :
# -acodec libfaac
# ajuster -threads selon besoins
#
# 14/12/2011 OH
# v 0.2 : 
#   * (debut de) sanitisation de l'entree
#   * extension de fichier parametrable (${2})
#
# 15/12/2011 OH
# v 0.3 :
#   * getopts pour passer les arguments en ligne de cde
#   * sanitisation un peu plus poussee
#   * extension fichier parametrable et automatise
#   * reecriture construction nom des fichiers de sortie
#   * fonctions
###############################################################################

###############################################################################
## automatic input parsing (sanitise?)
#usage="Usage: `basename ${0}` [options (-pctmesdh)] {filename}\n\
#       You must at least specify the file name\n\
#       "
#
#if [ $# -lt 1 ]
#then    
#       echo    
#       echo -e ${usage}
#       echo    
#       exit 0  
#fi
###############################################################################


###############################################################################
## getopts
PREVIEW_MODE=0
COPY_MODE=0
CRF_MODE=0
THREEPASS_MODE=0
MANUAL_MODE=0
HELP_MODE=0
while getopts ":pcrtm:e:s:d:h" Option; do
  case $Option in
    p) PREVIEW_MODE=1;;
    c) COPY_MODE=1;;
    r) CRF_MODE=1;;
    t) THREEPASS_MODE=1;;
    m) MANUAL_MODE=1; MODE_FILE="$OPTARG";;
    e) FILE_EXTENSION="$OPTARG";;
    s) SPOS_DEF=1; START_POSITION="$OPTARG";;
    d) DUR_DEF=1; DURATION="$OPTARG";;
    h) HELP_MODE=1;;
    ?) echo "Unrecognized option. Exit 7" ;;
  esac
done
shift $(($OPTIND - 1))
## end getopts
###############################################################################


###############################################################################
## help documentation
## end help documentation
###############################################################################


###############################################################################
## automatic input parsing (sanitise?)
usage="Usage: `basename ${0}` [options (-pcrtmesdh)] {filename}\n\
        You must at least specify the file name\n\
        Try -h for help\n\
        "
if [ $HELP_MODE = 0 ] && [ $# -lt 1 ]
then    
        echo
        echo "File name not found!"
        echo
        echo -e ${usage}
        echo
        exit 0  
fi
# if we have passed these checks, we presume there's a file name
infile="${1}"
## end input parsing
###############################################################################


###############################################################################
## tests

########################################
## no mode defined
if [ $HELP_MODE = 0 ] && [ $PREVIEW_MODE = 0 ] && [ $CRF_MODE = 0 ] && \
        [ $COPY_MODE = 0 ] && [ $THREEPASS_MODE = 0 ] && [ $MANUAL_MODE = 0 ]
then
        echo -e "No mode defined!\n\
        => Falling back to default help mode"
        # shouldn't we do nothing and exit?
        HELP_MODE=1
fi
########################################

########################################
## conflicting modes defined
if \
        { [ $PREVIEW_MODE = 1 ] && \
        { [ $CRF_MODE = 1 ] || [ $THREEPASS_MODE = 1 ] \
        || [ $MANUAL_MODE = 1 ] || [ $COPY_MODE = 1 ] ;} \
        ;} || { [ $COPY_MODE = 1 ] && \
        { [ $PREVIEW_MODE = 1 ] || [ $THREEPASS_MODE = 1 ] \
        || [ $MANUAL_MODE = 1 ] || [ $CRF_MODE = 1 ] ;} \
        ;} || { [ $CRF_MODE = 1 ] && \
        { [ $PREVIEW_MODE = 1 ] || [ $THREEPASS_MODE = 1 ] \
        || [ $MANUAL_MODE = 1 ] || [ $COPY_MODE = 1 ] ;} \
        ;} || { [ $THREEPASS_MODE = 1 ]&& \
        { [ $CRF_MODE = 1 ] || [ $PREVIEW_MODE = 1 ] \
        || [ $MANUAL_MODE = 1 ] || [ $COPY_MODE = 1 ] ;} \
        ;} || { [ $MANUAL_MODE = 1 ] && \
        { [ $CRF_MODE = 1 ] || [ $THREEPASS_MODE = 1 ] \
        || [ $PREVIEW_MODE = 1 ] || [ $COPY_MODE = 1 ] ;} \
        ;}
then
        echo -e "Conflicting modes defined!\n\
        => Falling back to default help mode"
        # shouldn't we do nothing and exit?
        HELP_MODE=1
        PREVIEW_MODE=0
        COPY_MODE=0
        CRF_MODE=0
        THREEPASS_MODE=0
        MANUAL_MODE=0
fi
########################################

########################################
## don't print help if an encode is planned
if \
        { [ $HELP_MODE = 1 ] && \
        { [ $CRF_MODE = 1 ] || [ $THREEPASS_MODE = 1 ] \
        || [ $MANUAL_MODE = 1 ] || [ $PREVIEW_MODE = 1 ] \
        || [ $COPY_MODE = 1 ] ;} \
        ;}
then
        no_display_help_message="We're not going to display help \
since you seem to have requested an encode \
and displaying the help could interfere."
        echo $no_display_help_message
fi
########################################

########################################
## file extension not defined
# check for presence of dot in file name taken from:
# http://www.linuxquestions.org/\
#       questions/programming-9/\
#       bash-search-for-a-pattern-within-a-string-variable-448022/
# see also:
# http://stackoverflow.com/\
#       questions/1473981/how-to-check-if-a-string-has-spaces-in-bash-shell
if { ! [[ "$infile" =~ ^.*\..*$ ]] ;} && [ $HELP_MODE != 1 ]; then
    echo -e "The file name doesn't seem to have an extension.\n\
  I don't know what to do with this.\n\
  Would you please review the situation and submit your request again?\n\
  Thank you."
    exit 0
elif [ $HELP_MODE != 1 ] && [ "$FILE_EXTENSION" = "" ] && \
        [[ "$infile" =~ ^.*\..*$ ]]; then
        echo "File extension not defined! This might not work!"
        echo "  => File extension seems to be: "${1##*.}
        FILE_EXTENSION=${1##*.}
        echo -e '       We have selected "'${FILE_EXTENSION}'"'\
                'as the file extension.'"\n"\
                '       I do sincerely hope this works...'
fi
########################################

########################################
## output files name construction
#
if [ $HELP_MODE != 1 ]; then
  if [[ "$infile" =~ ^.*\..*$ ]]; then
# http://stackoverflow.com/\
#       questions/965053/extract-filename-and-extension-in-bash
# much more sleek like this than with sed
    tmpfile=${1%.*}'_tmp.mp4'
    #touch "$tmpfile"
# file name creation requires quotes
# in case there are spaces or odd characters
#
    outfile=${1%.*}'.mp4'
    logfile=${1%.*}'.log'
    stafile=${1%.*}'.stats'
# redefine output file names for the copy function
    tmpfile_cut=${1%.*}'_tmp_cut.mp4'
    outfile_cut=${1%.*}'_cut.mp4'
    logfile_cut=${1%.*}'_cut.log'
    stafile_cut=${1%.*}'_cut.stats'
  else
    echo -e "The file name doesn't seem to have an extension.\n\
  I don't know what to do with this.\n\
  Would you please review the situation and submit your request again?\n\
  Thank you."
    exit 0
  fi
fi
#
# old method using sed, for comparison
#infile=${1}
#extension=${FILE_EXTENSION}
#tmpfile=`echo ${1} | sed "s/\.${extension}/_tmp\.mp4/"`
#outfile=`echo ${1} | sed "s/\.${extension}/\.mp4/"`
#logfile=`echo ${1} | sed "s/\.${extension}/\.log/"`
#stafile=`echo ${1} | sed "s/\.${extension}/\.stats/"`
########################################

## end tests
###############################################################################


###############################################################################
## functions

##
## TODO : do the file names need to be quoted in the ffmpeg call?
## see preview mode example
##

########################################
## plain copy
func_plain_copy () {
vid_opts="-vcodec copy"
aud_opts="-acodec copy"
mis_opts="-threads 2 -y"
startpos=$START_POSITION
duration=$DURATION
if [ $SPOS_DEF ] && [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" -t "$duration" \
        $mis_opts "$tmpfile_cut" &> "$logfile_cut"
        
        qt-faststart "$tmpfile_cut" "$outfile_cut" &>> "$logfile_cut"
elif [ $SPOS_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" \
        $mis_opts "$tmpfile_cut" &> "$logfile_cut"

qt-faststart "$tmpfile_cut" "$outfile_cut" &>> "$logfile_cut"
elif [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -t "$duration" \
        $mis_opts "$tmpfile_cut" &> "$logfile_cut"
        
qt-faststart "$tmpfile_cut" "$outfile_cut" &>> "$logfile_cut"
else
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        $mis_opts "$tmpfile_cut" &> "$logfile_cut"

qt-faststart "$tmpfile_cut" "$outfile_cut" &>> "$logfile_cut"
fi
}
########################################
## three pass
func_three_pass_encode () {
## options
vid_opts="-vcodec libx264 -b 512k -flags +loop+mv4 -cmp 256 \
         -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
         -me_method hex -subq 7 -trellis 1 -refs 5 -bf 3 \
         -flags2 +bpyramid+wpred+mixed_refs+dct8x8 -coder 1 -me_range 16 \
         -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10 \
         -qmax 51 -qdiff 4"
aud_opts="-acodec libmp3lame -ar 44100 -ab 96k"
mis_opts="-threads 2 -y"
startpos=$START_POSITION
duration=$DURATION
## ffmpeg call
if [ $SPOS_DEF ] && [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts -an \
        -ss "$startpos" -t "$duration" \
        $mis_opts -pass 1 "$tmpfile" &> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts -an \
        -ss "$startpos" -t "$duration" \
        $mis_opts -pass 3 "$tmpfile" &>> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" -t "$duration" \
        $mis_opts -pass 2 "$tmpfile" &>> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
elif [ $SPOS_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts -an \
        -ss "$startpos" \
        $mis_opts -pass 1 "$tmpfile" &> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts -an \
        -ss "$startpos" \
        $mis_opts -pass 3 "$tmpfile" &>> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" \
        $mis_opts -pass 2 "$tmpfile" &>> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
elif [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts -an \
        -t "$duration" \
        $mis_opts -pass 1 "$tmpfile" &> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts -an \
        -t "$duration" \
        $mis_opts -pass 3 "$tmpfile" &>> "$logfile"
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -t "$duration" \
        $mis_opts -pass 2 "$tmpfile" &>> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
else
ffmpeg \
        -i "$infile" $vid_opts -an \
        $mis_opts -pass 1 "$tmpfile" &> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts -an \
        $mis_opts -pass 3 "$tmpfile" &>> "$logfile"

ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        $mis_opts -pass 2 "$tmpfile" &>> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
fi
}
########################################

########################################
## crf
func_crf_encode () {
## options
vid_opts="-vcodec libx264 -crf 30 -flags +loop+mv4 -cmp 256 \
         -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
         -me_method hex -subq 7 -trellis 1 -refs 5 -bf 3 \
         -flags2 +bpyramid+wpred+mixed_refs+dct8x8 -coder 1 -me_range 16 \
         -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10 \
         -qmax 51 -qdiff 4"
aud_opts="-acodec libmp3lame -ar 44100 -ab 128k"
mis_opts="-threads 2 -y"
startpos=$START_POSITION
duration=$DURATION
## ffmpeg call
if [ $SPOS_DEF ] && [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" -t "$duration" \
        $mis_opts "$tmpfile" &> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
elif [ $SPOS_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -ss "$startpos" \
        $mis_opts "$tmpfile" &> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
elif [ $DUR_DEF ]; then
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        -t "$duration" \
        $mis_opts "$tmpfile" &> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
else
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        $mis_opts "$tmpfile" &> "$logfile"

qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
fi
}
########################################

########################################
## preview
func_preview_encode () {
## options
vid_opts="-vcodec libx264 -crf 30 -vpre libx264-lossless_ultrafast"
aud_opts="-acodec libmp3lame -ar 44100 -ab 96k"
mis_opts="-threads 4 -y"
## ffmpeg call
ffmpeg \
        -i "$infile" $vid_opts $aud_opts \
        $mis_opts "$outfile" &> "$logfile"
}
########################################

########################################
## manual
func_manual_encode () {
        echo "Not yet implemented!"
        exit 0
## options
}
########################################

########################################
## help
func_print_help () {
        # use heredoc...
        #$help_documentation
        # how do I call a here doc?
cat <<-Help-message
This script aims to convert and encode input video files.
You can either use pre-set modes with p, c, r or t switches, or your own \
personnally defined mode with the m switch.
It is mandatory to position one of these five switches.
If none is positionned, the script will simply display a help message.
The switches stand for:
-p: preview mode
-c: copy mode
-r: constant rate mode
-t: three pass mode
-m: manual mode
The file extension can be defined with the e switch.
Start position and duration of encoding are repectively defined \
with the s and d switches and are optionnal. They do nothing in the case of the preview mode. The duration of encoding is counted from the start position.
A typical command line call would be something like:
basename -r -e mpg -s "00:05:45" -d "01:45:10" "infile.mpg"
Help-message
# how do I put a here doc in a variable to call it when I need it?
}
########################################

## end functions
###############################################################################


###############################################################################
## function call
if [ $PREVIEW_MODE = 1 ]; then
        func_preview_encode
elif [ $COPY_MODE = 1 ]; then
        func_plain_copy
elif [ $CRF_MODE = 1 ]; then
        func_crf_encode
elif [ $THREEPASS_MODE = 1 ]; then
        func_three_pass_encode
elif [ $MANUAL_MODE = 1 ]; then
        func_manual_encode
elif [ $HELP_MODE = 1 ]; then
        func_print_help
fi
###############################################################################


###############################################################################
exit 0
###############################################################################


###############################################################################
## the old basic script
# exit 0 because we don't want to execute it
exit 0

########################################
## triple pass
## user defined options
#vid_opts="-vcodec libx264 -b 512k -flags +loop+mv4 -cmp 256 \
#        -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
#        -me_method hex -subq 7 -trellis 1 -refs 5 -bf 3 \
#        -flags2 +bpyramid+wpred+mixed_refs+dct8x8 -coder 1 -me_range 16 \
#        -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10\
#        -qmax 51 -qdiff 4"
#aud_opts="-acodec libmp3lame -ar 44100 -ab 96k"
#mis_opts="-threads 2 -y"
#startpos="00:14:46"
#duration="00:28:27"
#ffmpeg \
#       -i "$infile" $vid_opts -an \
#       -ss "$startpos" -t "$duration" \
#       $mis_opts -pass 1 "$tmpfile" &> "$logfile"
#ffmpeg \
#       -i "$infile" $vid_opts -an \
#       -ss "$startpos" -t "$duration" \
#       $mis_opts -pass 3 "$tmpfile" &>> "$logfile"
#ffmpeg \
#       -i "$infile" $vid_opts $aud_opts \
#       -ss "$startpos" -t "$duration" \
#       $mis_opts -pass 2 "$tmpfile" &>> "$logfile"
########################################

########################################
## simple pass crf
#vid_opts="-vcodec libx264 -crf 30 -flags +loop+mv4 -cmp 256 \
#        -partitions +parti4x4+parti8x8+partp4x4+partp8x8+partb8x8 \
#        -me_method hex -subq 7 -trellis 1 -refs 5 -bf 3 \
#        -flags2 +bpyramid+wpred+mixed_refs+dct8x8 -coder 1 -me_range 16 \
#        -g 250 -keyint_min 25 -sc_threshold 40 -i_qfactor 0.71 -qmin 10\
#        -qmax 51 -qdiff 4"
#aud_opts="-acodec libmp3lame -ar 44100 -ab 96k"
#mis_opts="-threads 2 -y"
#startpos="00:14:46"
#duration="00:28:27"
#ffmpeg \
#       -i "$infile" $vid_opts $aud_opts \
#       -ss "$startpos" -t "$duration" \
#       $mis_opts "$tmpfile" &> "$logfile"
#qt-faststart "$tmpfile" "$outfile" &>> "$logfile"
########################################

###############################################################################

## script end
###############################################################################
