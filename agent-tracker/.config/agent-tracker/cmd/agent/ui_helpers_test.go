package main

import "testing"

func TestAgentCtrlNavigationKeys(t *testing.T) {
	if !isAgentCtrlPrevKey("ctrl+k") {
		t.Fatalf("expected ctrl+k to be the previous-item key")
	}
	if !isAgentCtrlNextKey("ctrl+j") {
		t.Fatalf("expected ctrl+j to be the next-item key")
	}
	if isAgentCtrlPrevKey("ctrl+u") {
		t.Fatalf("did not expect ctrl+u to remain the previous-item key")
	}
	if isAgentCtrlNextKey("ctrl+e") {
		t.Fatalf("did not expect ctrl+e to remain the next-item key")
	}
}

func TestAgentVimDirectionKeys(t *testing.T) {
	if !isAgentMoveLeftKey("h") || !isAgentMoveRightKey("l") {
		t.Fatalf("expected h/l to map to left/right")
	}
	if !isAgentMoveUpKey("k") || !isAgentMoveDownKey("j") {
		t.Fatalf("expected k/j to map to up/down")
	}
	if !isAgentAltPrevKey("alt+k") || !isAgentAltNextKey("alt+j") {
		t.Fatalf("expected alt+k/j to map to prev/next")
	}
	if isAgentMoveLeftKey("n") || isAgentMoveRightKey("i") || isAgentMoveUpKey("u") || isAgentMoveDownKey("e") {
		t.Fatalf("did not expect legacy u/e/n/i keys to remain active")
	}
}
