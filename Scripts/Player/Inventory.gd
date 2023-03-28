class_name Inventory
extends Node

signal item_amount_changed(idx: int, item: InventoryItem, new_amount: int, delta: int)
signal slot_count_changed(new_count)
signal overweight
signal normal_weight

class InventorySlot:
	var item : InventoryItem = null
	var amount := 0
	var item_name : String :
		get:
			if item == null:
				return ""
			return item.name
	var item_weight : float :
		get:
			if item == null:
				return 0.
			return item.weight
			
	func _init(i: InventoryItem, a: float):
		item = i
		amount = a

@export_range(1, 32) var max_slots = 16
@export_range(.0001, 2000., .0001) var max_weight = 1000.

var slots : Array[InventorySlot] = []
var current_weight : float = 0 :
	set (w):
		if current_weight < max_weight and w >= max_weight:
			overweight.emit()
		elif current_weight >= max_weight and w < max_weight:
			normal_weight.emit()
		
		current_weight = w
	
func item_idx(item: InventoryItem, not_found_fail := false) -> int:
	if len(slots) == 0:
		return 0
	
	for idx in range(len(slots)):
		var slot := slots[idx]
		if slot.item_name == item.name:
			return idx
	
	if len(slots) < max_slots and (not not_found_fail):
		# There's still room
		return len(slots)
		
	# All slots full
	return -1

func add_item(item: InventoryItem, amount := 1) -> bool:
	var idx := item_idx(item)
	
	if idx == -1:
		push_error("Inventory already full - failed to add item!")
		return false
		
	if idx == len(slots):
		# Append at the end
		var slot := InventorySlot.new(item, 0)
		slots.append(slot)
		slot_count_changed.emit(len(slots))
	elif slots[idx].amount + amount >= slots[idx].item.max_stack:
		push_error("Max stack reached - failed to add item!")
		return false
		
	slots[idx].item = item
	
	_change_item_amnt(idx, amount)
	
	return true

func remove_item(item: InventoryItem, amount := 1, remove_exact := false) -> bool:
	var idx := item_idx(item, true)
	
	if idx == -1:
		push_error("Item not found!")
		return false
		
	if not remove_exact:
		amount = min(amount, slots[idx].amount)
	elif slots[idx].amount < amount:
		push_error("Can't remove more items than those present!")
		return false
		
	_change_item_amnt(idx, -amount)
	
	return true
	
func _change_item_amnt(idx: int, delta_amnt := 1):
	slots[idx].amount += delta_amnt
	item_amount_changed.emit(idx, slots[idx].item, slots[idx].amount, delta_amnt)

	current_weight += slots[idx].item_weight * delta_amnt
	
	if slots[idx].amount <= 0:
		slots.remove_at(idx)
		slot_count_changed.emit(len(slots))
		
func _to_string():
	var tmp := {}
	
	for s in slots:
		tmp[s.item_name] = s.amount
	
	return str(tmp)
