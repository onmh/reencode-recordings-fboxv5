#!/usr/bin/python
# -*- coding:Latin-1 -*-

# Main #######################################################################

if __name__ == "__main__":

    deb_heure = input('Heure de début ')
    deb_minute = input('Minute de début ')
    deb_seconde = input('Seconde de début ')
    fin_heure = input('Heure de fin ')
    fin_minute = input('Minute de fin ')
    fin_seconde = input('Seconde de fin ')

    t_deb = deb_heure * 3600 + deb_minute * 60 + deb_seconde
    print "Le debut est à ",t_deb,"s"
    print
    t_fin = fin_heure * 3600 + fin_minute * 60 + fin_seconde
    print "La fin est à ",t_fin,"s"
    print
    t_dur = t_fin - t_deb
    print "La durée totale est de ",t_dur,"s"
    print

    dur_heure = t_dur / 3600
    print "La durée est de",dur_heure,"h"
    res_heure = t_dur % 3600
    dur_minute = res_heure / 60
    print dur_minute,"m"
    dur_seconde = res_heure % 60
    print "et",dur_seconde,"s"

    print
    print "Au format requis par ffmpeg ceci \
s'écrit",dur_heure,":",dur_minute,":",dur_seconde
