extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(0.1), YIELD)
	card = cards[0]
	target = cards[2]


func test_per_token_and_modify_token_per():
	yield(table_move(card, Vector2(100,200)), "completed")
	card.tokens.mod_token("void",5)
	yield(yield_for(0.1), YIELD)
	card.scripts = {"manual": {
		"board": [
			{"name": "mod_tokens",
			"subject": "self",
			"token_name":  "bio",
			"modification": "per_token",
			"per_token": {
				"subject": "self",
				"token_name": "void"}
			},
		]}
	}
	card.execute_scripts()
	var bio_token = card.tokens.get_token("bio")
	assert_not_null(bio_token,
		"Put 1 Bio token per void token on this card")
	if bio_token:
		assert_eq(bio_token.count, 5)
	card.scripts = {"manual": {
		"board": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_count": "per_token",
			"src_container": deck,
			"dest_container": hand,
			"subject_index": "top",
			"per_token": {
				"subject": "self",
				"token_name": "void"}
			},
		]}
	}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 9,
			"Draw 1 card per void token on this card")

func test_per_property():
	card.modify_property("Cost", 3)
	card.scripts = {"manual": {
		"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_count": "per_property",
			"src_container": deck,
			"dest_container": hand,
			"subject_index": "top",
			"per_property": {
				"subject": "self",
				"property_name": "Cost"}
			},
		]}
	}
	card.execute_scripts()
	yield(yield_for(0.5), YIELD)
	assert_eq(hand.get_card_count(), 8,
		"Draw 1 card per cost of this card.")


func test_per_tutor_and_spawn_card_per():
	target.scripts = {"manual": {"hand": [
			{"name": "spawn_card",
			"scene_path": "res://src/custom/CGFCardTemplate.tscn",
			"object_count": "per_tutor",
			"board_position":  Vector2(100,200),
			"per_tutor": {
				"subject": "tutor",
				"subject_count": "all",
				"src_container":  cfc.NMAP.deck,
				"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}]
			}}]}}
	target.execute_scripts()
	yield(yield_for(0.3), YIELD)
	assert_eq(4,board.get_card_count(),
		"Spawn 1 card per Blue card in the deck")


func test_per_boardseek():
	yield(table_move(cards[1], Vector2(100,200)), "completed")
	yield(table_move(cards[2], Vector2(300,200)), "completed")
	yield(table_move(cards[3], Vector2(500,200)), "completed")
	yield(table_move(cards[4], Vector2(700,200)), "completed")
	card.scripts = {"manual": {"hand": [
			{"name": "move_card_to_container",
			"subject": "index",
			"subject_count": "per_boardseek",
			"src_container": deck,
			"dest_container": hand,
			"subject_index": "top",
			"per_boardseek": {
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{"filter_properties": {"Power": 0}}]
			}}]}}
	card.execute_scripts()
	yield(yield_for(0.3), YIELD)
	assert_eq(hand.get_card_count(), 3,
			"Draw 1 card per 0-cost card on board")
