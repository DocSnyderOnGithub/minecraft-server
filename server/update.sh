#!/bin/bash

set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null \
	|| exit 1
source "../contrib/utils.sh" || exit 1
become_minecaft "./update.sh"


################################################################
# Download paper and prepare plugins
PREFERRED_PAPER_VERSION="1.21.11"
FALLBACK_PAPER_VERSION="1.21.10"

download_paper paper.jar ${PREFERRED_PAPER_VERSION}

# Create plugins directory
mkdir -p plugins \
	|| die "Could not create directory 'plugins'"
# Create optional plugins directory
mkdir -p plugins/optional \
	|| die "Could not create directory 'plugins/optional'"


################################################################
# Download plugins
# Can use the following util functions to add plugins to the autoupdater:
# syntax: command (required argument) [optional argument]
# - download_file (url) (output file) [failure message]
# - download_latest_github_release (repo) (remote filename) (output file)
#  -> {TAG} will be replaced with the release tag
#  -> {VERSION} will be replaced with release tag excluding a leading v, if present
# - download_from_json_feed (feed url) (jq parser) (output file)
# - download_from_hangar (project) (platform) (output file)
# - download_from_modrinth (mod ID/name) (platform) (output file) [minecraft version]

substatus "Downloading vane plugins"
for module in admin bedtime core enchantments permissions portals regions trifles; do
	download_latest_github_release "oddlama/vane" "vane-$module-{VERSION}.jar" "plugins/vane-$module.jar"
done

substatus "Downloading ProtocolLib from github"
#download_file "https://ci.dmulloy2.net/job/ProtocolLib/lastSuccessfulBuild/artifact/build/libs/ProtocolLib.jar" plugins/ProtocolLib.jar
# url changed...
download_file "https://github.com/dmulloy2/ProtocolLib/releases/download/5.4.0/ProtocolLib.jar" plugins/ProtocolLib.jar

substatus "Downloading Bluemap from github/hangar"
# download_latest_github_release "BlueMap-Minecraft/BlueMap" "BlueMap-{VERSION}-spigot.jar" plugins/bluemap.jar
# download_file "https://hangarcdn.papermc.io/plugins/Blue/BlueMap/versions/5.15/PAPER/bluemap-5.15-paper.jar" plugins/bluemap.jar
download_from_hangar BlueMap PAPER plugins/bluemap.jar

substatus "Downloading WorldEdit from modrinth"
download_from_modrinth "worldedit" "paper" plugins/worldedit.jar ${PREFERRED_PAPER_VERSION}

substatus "Downloading WorldGuard from modrinth"
# download_from_modrinth "worldguard" "paper" plugins/worldguard.jar ${PREFERRED_PAPER_VERSION}
download_from_modrinth "worldguard" "paper" plugins/worldguard.jar ${FALLBACK_PAPER_VERSION}
# download_file "https://dev.bukkit.org/projects/worldguard/files/latest" plugins/worldguard.jar  ## !captcha!
# https://cdn.modrinth.com/data/1u6JkXh5/versions/3ISh7ADm/worldedit-bukkit-7.3.17.jar

substatus "Downloading WorldGuard plugin for BlueMap from github"
download_latest_github_release "Mark-225/BlueBridge" "BlueBridgeCore-{VERSION}.jar" "plugins/BlueBridgeCore.jar"
download_latest_github_release "Mark-225/BlueBridge" "BlueBridgeWB-{VERSION}.jar" "plugins/BlueBridgeWB.jar"
download_latest_github_release "Mark-225/BlueBridge" "BlueBridgeWG-{VERSION}.jar" "plugins/BlueBridgeWG.jar"

substatus "Downloading Advanced Portals from modrinth"
download_from_modrinth "advanced-portals" "paper" plugins/Advanced-Portals.jar

substatus "Downloading teawaystones from modrinth"
download_from_modrinth "teawaystones" "paper" plugins/Waystones.jar

substatus "Downloading Versioning support from hangar"
download_from_hangar ViaVersion PAPER plugins/ViaVersion.jar
download_from_hangar ViaBackwards PAPER plugins/ViaBackwards.jar
# download_from_hangar Geyser PAPER plugins/Geyser.jar


substatus "Downloading spark server profiler from json feed"
download_from_json_feed \
  "https://ci.lucko.me/job/spark/lastSuccessfulBuild/api/json" \
  '.artifacts[]
   | select(.fileName | test("^spark-.*-bukkit\\.jar$"))
   | "https://ci.lucko.me/job/spark/lastSuccessfulBuild/artifact/"+.relativePath' \
  "plugins/Spark.jar"
