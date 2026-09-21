# Autoload singleton to handle global game state and variables
extends Node

###############
#  Constants  #
###############

const LEVEL_0 = "res://scenes/levels/level_0.tscn"
const LOBBY_LEVEL = "res://scenes/levels/lobby_level.tscn"
const MAIN_MENU = "res://scenes/levels/main_menu.tscn"


################
#  Game State  #
################

var game_starting: bool = false
