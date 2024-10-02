#!/bin/sh

 DIR=~/IdeaProjects/work/pioneer_media_server_test;

read -p "Необходимо копировать файлы? (n/y): " is_copy

if [ "$is_copy" = "y" ]; then
  if ! [ -d $DIR ]; then
    echo "$DIR does not exist, creating...";
    mkdir $DIR
  fi;

  rsync -r --exclude 'config' --include='files.ex' --exclude './files/*' ./ $DIR;
  echo "server is successfully copied"
fi


read -p "Необходимо делать миграцию? (n/y): " migrate

if [ "$migrate" = "y" ]; then
  gnome-terminal -- bash -c 'cd ~/IdeaProjects/work/pioneer_media_server_test; mix ecto.migrate; iex -S mix phx.server; exec bash'
else
  gnome-terminal -- bash -c 'cd ~/IdeaProjects/work/pioneer_media_server_test; iex -S mix phx.server; exec bash'
fi

