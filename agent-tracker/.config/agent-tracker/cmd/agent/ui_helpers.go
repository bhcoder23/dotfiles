package main

import (
	"strings"
	"unicode"
)

func wrapText(text string, width int) []string {
	if width <= 0 {
		return []string{""}
	}
	if text == "" {
		return []string{""}
	}
	words := strings.Fields(text)
	if len(words) == 0 {
		return []string{""}
	}
	var lines []string
	current := words[0]
	for _, word := range words[1:] {
		candidate := current + " " + word
		if len([]rune(candidate)) <= width {
			current = candidate
			continue
		}
		lines = append(lines, current)
		current = word
	}
	lines = append(lines, current)
	return lines
}

func truncate(text string, width int) string {
	if width <= 0 {
		return ""
	}
	runes := []rune(text)
	if len(runes) <= width {
		return text
	}
	if width == 1 {
		return string(runes[:1])
	}
	return string(runes[:width-1]) + "…"
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func previousWordBoundary(runes []rune, cursor int) int {
	i := cursor
	for i > 0 && unicode.IsSpace(runes[i-1]) {
		i--
	}
	for i > 0 && !unicode.IsSpace(runes[i-1]) {
		i--
	}
	return i
}

func isAgentCtrlPrevKey(key string) bool {
	return key == "ctrl+k"
}

func isAgentCtrlNextKey(key string) bool {
	return key == "ctrl+j"
}

func isAgentAltPrevKey(key string) bool {
	return key == "alt+k"
}

func isAgentAltNextKey(key string) bool {
	return key == "alt+j"
}

func isAgentMoveUpKey(key string) bool {
	return key == "k" || key == "up"
}

func isAgentMoveDownKey(key string) bool {
	return key == "j" || key == "down"
}

func isAgentMoveLeftKey(key string) bool {
	return key == "h" || key == "left"
}

func isAgentMoveRightKey(key string) bool {
	return key == "l" || key == "right"
}
