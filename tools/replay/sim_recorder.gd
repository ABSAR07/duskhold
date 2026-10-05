class_name SimRecorder
extends RefCounted
## RED stub: replaced by the real recorder in the GREEN commit.

const HANDLED: Array[String] = []


static func attach(_ctx: RunContext) -> SimRecorder:
	return SimRecorder.new()


func lines() -> PackedStringArray:
	return PackedStringArray()


func digest() -> String:
	return ""
