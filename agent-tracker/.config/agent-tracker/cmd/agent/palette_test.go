package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

func TestDetectPaletteMainRepoRootFallsBackToGitRoot(t *testing.T) {
	repoRoot := t.TempDir()
	cmd := exec.Command("git", "init")
	cmd.Dir = repoRoot
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git init failed: %v (%s)", err, string(output))
	}
	nested := filepath.Join(repoRoot, "nested", "dir")
	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatalf("mkdir nested dir: %v", err)
	}
	got := detectPaletteMainRepoRoot(nested, nil)
	want, err := filepath.EvalSymlinks(repoRoot)
	if err != nil {
		t.Fatalf("resolve expected repo root: %v", err)
	}
	gotResolved, err := filepath.EvalSymlinks(got)
	if err != nil {
		t.Fatalf("resolve detected repo root: %v", err)
	}
	if filepath.Clean(gotResolved) != filepath.Clean(want) {
		t.Fatalf("expected repo root %q, got %q", want, gotResolved)
	}
}
