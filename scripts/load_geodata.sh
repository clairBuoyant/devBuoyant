#!/bin/bash

set -eu

# TODO: Incorporate into initial build process.
# TODO: Refactor (maybe in backend as py script) and integrate entrypoint to run script in docker remotely.

function container_setup {
    echo "Running container setup..."
    apt-get update

    if [ ! -x "$(which curl)" ]; then
        echo "curl not found"
        echo "installing curl..."
        apt-get install curl -y
    fi

    if [ ! -x "$(which unzip)" ]; then
        echo "unzip not found"
        echo "installing unzip..."
        apt-get install unzip -y
    fi

    if [ ! -x "$(which shp2pgsql)" ]; then
        echo "shp2pgsql not found"
        echo "installing shp2pgsql via postgis"
        apt-get install postgis -y
    fi

    echo "Completed initial setup."
}

function curl_and_unzip {
    url=$1
    filename=$2

    if [ -x "$(which curl)" ]; then
        echo "Downloading..."
        curl -o $2 -sfL $url
        echo "Downloaded: $2"

        echo "Extracting data from zip file..."
        unzip $2 -d /tmp/coastline_data
        echo "Unzip complete."

        mv $2 /tmp/downloads
        echo "Cached zipfile: $2"
    else
        echo "Could not find curl." >&2
    fi
}

function trim_filename_from_path_or_url {
    path_or_url=$1

    echo ${path_or_url##*/}
}

# curl the following, moved zipped files into namespace folders
function get_osmdata {
    # This data is Copyright 2022 OpenStreetMap contributors.
    # It is available under the Open Database License (ODbL).
    # temporarily exclude: "https://osmdata.openstreetmap.de/download/land-polygons-complete-4326.zip"
    declare -a sites=("https://osmdata.openstreetmap.de/download/coastlines-split-4326.zip" "https://osmdata.openstreetmap.de/download/land-polygons-split-4326.zip" "https://osmdata.openstreetmap.de/download/water-polygons-split-4326.zip")

    if [ ! -d "/tmp/coastline_data" ]; then
        mkdir "/tmp/coastline_data"
        mkdir "/tmp/coastline_data/load-sql"
    fi

    if [ ! -d "/tmp/downloads" ]; then
        mkdir "/tmp/downloads"
    fi

    for site in "${sites[@]}"; do
        filename=$(trim_filename_from_path_or_url $site)
        curl_and_unzip $site "/tmp/coastline_data/$filename"
    done
}

# TODO: geog or geom
function generate_create_tables_in_sql {
    location_to_generate_file=$1

    echo "SET CLIENT_ENCODING TO UTF8;
    SET STANDARD_CONFORMING_STRINGS TO ON;
    BEGIN;
    CREATE TABLE \"public\".\"land_polygons\" (gid serial,\"x\" int4,\"y\" int4);
    CREATE TABLE \"public\".\"lines\" (gid serial, \"fid\" float8);
    CREATE TABLE \"public\".\"water_polygons\" (gid serial,\"x\" int4,\"y\" int4);
    SELECT AddGeometryColumn('public','land_polygons','geog','4326','MULTIPOLYGON',2);
    SELECT AddGeometryColumn('public','lines','geog','4326','MULTILINESTRING',2);
    SELECT AddGeometryColumn('public','water_polygons','geog','4326','MULTIPOLYGON',2);
    COMMIT;" > "${location_to_generate_file}/init_tables.sql"
}

function transform_shapes_to_sql {
    root_data_folder=$1

    generate_create_tables_in_sql "$root_data_folder"

    for folder in $root_data_folder/*; do
        files_in_folder_to_sql $folder
    done
}

function files_in_folder_to_sql {
    path_to_folder=$1

    shapes_folder_name=$(basename -- "$path_to_folder")

    shapes_to_pgsql $path_to_folder $shapes_folder_name
}

function split {
    name="${1%.*}"
    ext="${1##*.}"
    echo $(basename -- "$name") $ext
}

function upper {
    str="${1^^}"
    echo "$str"
}

function shapes_to_pgsql {
    shapes_folder=$1

    local filename extension

    for shapefile in $(find $shapes_folder/ -type f \( -iname \*.shp -o -iname \*.shx -o -iname \*.dbf \)); do
        read filename extension < <(split $shapefile)
        shape_to_pgsql $shapefile $filename $extension
    done
}

# .shp — shape format; the feature geometry itself
# .shx - shape index format; a positional index of the feature geometry
# .dbf - attribute format; columnar attributes for each shape, in dBase III
function shape_to_pgsql {
    filename_with_path=$1
    filename=$2
    extension=$(upper $3)

    shapes_folder_name=$(basename -- "$path_to_folder")

    shp2pgsql -a -D -s 4326 -i -I -G "${filename_with_path}" "public.${filename}" > "/tmp/coastline_data/load-sql/${extension}_${filename}.sql"
    echo "${filename_with_path} was converted to load-sql/${extension}_${filename}.sql"
}

function send_sql_files_to_psql {
    sql_files=$1

    echo "Creating tables for geodata..."
    psql -U postgres -f "/tmp/coastline_data/init_tables.sql"
    echo "Created tables."
    for sql_file in $sql_files/*.sql; do
        filename=$(basename -- "$sql_file")
        echo "Loading db with data from $filename..."
        psql -U postgres -f "${sql_file}"
        echo "Successfully seeded from $filename"
    done
}

function load_geodata {
    container_setup
    get_osmdata
    transform_shapes_to_sql "/tmp/coastline_data"
    send_sql_files_to_psql "/tmp/coastline_data/load-sql"
    cleanup
    echo "Loaded geodata successfully."
}

function cleanup {
    read -p "Do you want to permanently remove coastline_data? [y/n] " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf /tmp/coastline_data
        echo "\nSuccessfully deleted coastline_data"
    fi
    exit 0
}

load_geodata

exit 0
