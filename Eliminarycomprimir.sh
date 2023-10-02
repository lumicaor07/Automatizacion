#!/bin/bash
salida=$(argumento)
day=$(day)
directory=$(directory)

if [[ "$salida" == "Eliminar" ]];
then 
	num_archivos_eliminados=$(find "$directory" -type f -mtime "$day" -exec rm {} \; -print | wc -l)
    echo "Se han eliminado $num_archivos_eliminados archivos en la carpeta $directory"
	sleep 10s
	num=$(ls -p $directory | grep -v / | wc -l)
    message="Se eliminaron los archivos en esta ruta y quedaron: $num archivos"
	echo "$message"
	echo
else 
    find $directory -mtime $day -type f -exec gzip -1 {} \;
	sleep 10s
	num=$(ls -p $directory | grep -v / | wc -l)
	message="Se comprimieron los archivos en esta ruta  y quedaron: $num archivos"
	echo "$message"
	echo	
fi
