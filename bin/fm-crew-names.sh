#!/usr/bin/env bash
# fm-crew-names.sh - the crew-name pool and picker for spawned workers.
#
# Every fresh ship or scout spawn gets a random crew name from a mixed pool of
# real sailors, explorers, naval officers, pirates, fictional seafarers, and
# space sailors. bin/fm-spawn.sh records it as crew_name= in state/<id>.meta,
# where a relaunch preserves it; the name is presentation only and never an
# endpoint identity, so every lookup still uses the task id and fm-<id> label.
#
# Usage:
#   fm-crew-names.sh pick [<state-dir>]   print a random name not recorded as
#                                         crew_name= in any <state-dir>/*.meta
#   fm-crew-names.sh list                 print the whole pool, one per line
#
# Sourceable: defines fm_crew_names_pool, fm_crew_name_pick, and
# fm_crew_name_valid without running anything.
# When every pool name is taken the picker appends a roman-numeral suffix
# ("Nemo II"), so a pick never fails for lack of names.

fm_crew_names_pool() {
  cat <<'EOF'
Ferdinand Magellan
Christopher Columbus
Vasco da Gama
Zheng He
Leif Erikson
Erik the Red
Ragnar Lothbrok
Vicky the Viking
Halvar
Bjorn Ironside
Amerigo Vespucci
Bartolomeu Dias
James Cook
Abel Tasman
Henry Hudson
Jacques Cartier
Francis Drake
Walter Raleigh
William Bligh
Fletcher Christian
Ernest Shackleton
Roald Amundsen
Fridtjof Nansen
Willem Barentsz
Vitus Bering
John Franklin
Matthew Flinders
Joshua Slocum
Robin Knox-Johnston
Ellen MacArthur
Thor Heyerdahl
Jacques Cousteau
Horatio Nelson
John Paul Jones
Thomas Cochrane
David Farragut
Michiel de Ruyter
Maarten Tromp
Yi Sun-sin
Togo Heihachiro
Chester Nimitz
Grace Hopper
Andrea Doria
Piet Hein
Edward Pellew
Blackbeard
Anne Bonny
Mary Read
Calico Jack
Bartholomew Roberts
Henry Morgan
William Kidd
Grace O'Malley
Ching Shih
Jean Lafitte
Stede Bonnet
Samuel Bellamy
Francois l'Olonnais
Hayreddin Barbarossa
Klaus Stortebeker
Henry Every
Charles Vane
Edward Low
Olivier Levasseur
Jeanne de Clisson
Turgut Reis
Odysseus
Jason
Sinbad
Ishmael
Captain Ahab
Queequeg
Starbuck
Robinson Crusoe
Captain Nemo
Long John Silver
Jim Hawkins
Captain Flint
Billy Bones
Ben Gunn
Captain Hook
Mr. Smee
Jack Sparrow
Hector Barbossa
Will Turner
Elizabeth Swann
Davy Jones
Joshamee Gibbs
Captain Haddock
Horatio Hornblower
Jack Aubrey
Stephen Maturin
Peter Blood
Popeye
Captain Barnacle
Captain Birdseye
The Dread Pirate Roberts
Captain Jack Harkness
Moana
Maui
Captain Pugwash
Captain Ross
Sandokan
Corto Maltese
Captain Queeg
Billy Budd
Captain Vere
Marlow
Lord Jim
Monkey D. Luffy
Roronoa Zoro
Nami
Usopp
Sanji
Tony Tony Chopper
Nico Robin
Franky
Brook
Jinbe
Gol D. Roger
Shanks
Whitebeard
Portgas D. Ace
Trafalgar Law
Boa Hancock
Buggy
Dracule Mihawk
Monkey D. Garp
Silvers Rayleigh
Eustass Kid
Smoker
Koby
Captain Harlock
Emeraldas
Captain Tylor
James T. Kirk
Spock
Leonard McCoy
Montgomery Scott
Nyota Uhura
Hikaru Sulu
Pavel Chekov
Christine Chapel
Christopher Pike
Una Chin-Riley
Jean-Luc Picard
William Riker
Data
Geordi La Forge
Worf
Deanna Troi
Beverly Crusher
Tasha Yar
Wesley Crusher
Guinan
Benjamin Sisko
Kira Nerys
Jadzia Dax
Odo
Quark
Miles O'Brien
Julian Bashir
Kathryn Janeway
Chakotay
Tuvok
B'Elanna Torres
Tom Paris
Harry Kim
Seven of Nine
Neelix
Jonathan Archer
T'Pol
Trip Tucker
Hoshi Sato
Michael Burnham
Saru
Sylvia Tilly
Paul Stamets
Carol Freeman
Beckett Mariner
Brad Boimler
Han Solo
Chewbacca
Lando Calrissian
Leia Organa
Luke Skywalker
Poe Dameron
Hera Syndulla
Wedge Antilles
Admiral Ackbar
Din Djarin
Malcolm Reynolds
Zoe Washburne
Hoban Washburne
Jayne Cobb
Kaylee Frye
Inara Serra
River Tam
William Adama
Lee Adama
Kara Thrace
Laura Roslin
Saul Tigh
Gaius Baltar
Sharon Valerii
James Holden
Naomi Nagata
Amos Burton
Alex Kamal
Chrisjen Avasarala
Camina Drummer
Bobbie Draper
Ellen Ripley
Dallas
Arthur Dent
Ford Prefect
Zaphod Beeblebrox
Trillian
Marvin
Ender Wiggin
Honor Harrington
Miles Vorkosigan
Cordelia Naismith
John Sheridan
Susan Ivanova
Jeffrey Sinclair
Dave Lister
Arnold Rimmer
Kryten
Peter Quill
Gamora
Rocket
Drax
Groot
Leela
Philip J. Fry
Bender
Hubert Farnsworth
Zapp Brannigan
Kif Kroker
Buck Rogers
Flash Gordon
Dan Dare
Yuri Gagarin
Valentina Tereshkova
Neil Armstrong
Buzz Aldrin
Michael Collins
Sally Ride
Chris Hadfield
Mae Jemison
Peggy Whitson
John Glenn
Alexei Leonov
Jim Lovell
EOF
}

# A recorded name is safe to render into a one-line meta value and a Herdr
# label: nonempty, printable, and free of the label separator and key syntax.
fm_crew_name_valid() {  # <name>
  local name=$1
  [ -n "$name" ] || return 1
  [ "${#name}" -le 48 ] || return 1
  case "$name" in
    *'·'*|*'='*|*':'*|*'	'*) return 1 ;;
  esac
  printf '%s' "$name" | LC_ALL=C grep -q '[^ -~]' && return 1
  return 0
}

fm_crew_names_in_use() {  # <state-dir>
  local state=$1 meta
  [ -d "$state" ] || return 0
  for meta in "$state"/*.meta; do
    [ -f "$meta" ] || continue
    sed -n 's/^crew_name=//p' "$meta" | tail -n 1
  done
}

fm_crew_name_pick() {  # [<state-dir>]
  local state=${1:-} used free name suffix
  used=$(fm_crew_names_in_use "$state")
  free=$(fm_crew_names_pool | LC_ALL=C grep -vxF -f <(printf '%s\n' "$used") || true)
  [ -n "$used" ] || free=$(fm_crew_names_pool)
  if [ -n "$free" ]; then
    printf '%s\n' "$free" | shuf -n 1
    return 0
  fi
  for suffix in II III IV V VI VII VIII IX X; do
    free=$(fm_crew_names_pool | sed "s/\$/ $suffix/" | LC_ALL=C grep -vxF -f <(printf '%s\n' "$used") || true)
    if [ -n "$free" ]; then
      printf '%s\n' "$free" | shuf -n 1
      return 0
    fi
  done
  name=$(fm_crew_names_pool | shuf -n 1)
  printf '%s %s\n' "$name" "$RANDOM"
}

if ! (return 0 2>/dev/null); then
  set -eu
  case "${1:-}" in
    pick) fm_crew_name_pick "${2:-}" ;;
    list) fm_crew_names_pool ;;
    -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) echo "usage: fm-crew-names.sh pick [<state-dir>] | list" >&2; exit 2 ;;
  esac
fi
