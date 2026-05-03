package main

import "testing"

func TestPaletteWorkflowActions(t *testing.T) {
	runtime := &paletteRuntime{
		mainRepoRoot: "/tmp/repo",
		currentPath:  "/tmp/repo",
		currentFlow: paletteFlowContext{
			Branch:     "feature/current",
			RepoRoot:   "/tmp/repo",
			TmuxWindow: "@1",
		},
	}

	actions := runtime.buildActions()
	titles := make(map[string]bool, len(actions))
	for _, action := range actions {
		titles[action.Title] = true
	}

	if !titles["Workflows"] {
		t.Fatalf("expected Workflows action, got %#v", actions)
	}
	if titles["Start workflow"] || titles["Resume workflow"] || titles["Destroy workflow"] {
		t.Fatalf("expected split workflow actions to be removed, got %#v", actions)
	}
}

func TestPaletteWorkflowKeys(t *testing.T) {
	makeModel := func() *paletteModel {
		return &paletteModel{
			runtime: &paletteRuntime{
				mainRepoRoot: "/tmp/repo",
				currentFlow: paletteFlowContext{
					Branch:     "feature/current",
					RepoRoot:   "/tmp/repo",
					TmuxWindow: "@2",
				},
			},
			state: paletteUIState{
				Mode:     paletteModeWorkflows,
				Selected: 0,
			},
			workflows: []paletteWorkflowEntry{
				{
					RepoRoot:        "/tmp/repo",
					Branch:          "feature/old",
					Status:          "stopped",
					WorktreePath:    "/tmp/worktrees/feature-old",
					TmuxSessionName: "1-repo",
					TmuxWindowID:    "@1",
				},
				{
					RepoRoot:        "/tmp/repo",
					Branch:          "feature/current",
					Status:          "running",
					WorktreePath:    "/tmp/worktrees/feature-current",
					TmuxSessionName: "1-repo",
					TmuxWindowID:    "@2",
					Active:          true,
				},
			},
		}
	}

	t.Run("plain typing updates filter instead of triggering action", func(t *testing.T) {
		model := makeModel()
		updated, _ := model.updateWorkflows("a")
		got := updated.(*paletteModel)

		if got.state.Mode != paletteModeWorkflows {
			t.Fatalf("expected to stay in workflows mode, got %v", got.state.Mode)
		}
		if string(got.state.Filter) != "a" {
			t.Fatalf("expected filter text to be updated, got %q", string(got.state.Filter))
		}
		if got.result.Kind != paletteResultClose {
			t.Fatalf("expected no action result, got %#v", got.result)
		}
	})

	t.Run("ctrl+r resumes selected workflow", func(t *testing.T) {
		model := makeModel()
		updated, _ := model.updateWorkflows("ctrl+r")
		got := updated.(*paletteModel)

		if got.result.Kind != paletteResultRunAction {
			t.Fatalf("expected run action result, got %#v", got.result)
		}
		if got.result.Action.Kind != paletteActionResumeFlow {
			t.Fatalf("expected resume action, got %#v", got.result.Action)
		}
		if got.result.Action.RepoRoot != "/tmp/repo" || got.result.Input != "feature/old" {
			t.Fatalf("expected selected workflow target, got action=%#v input=%q", got.result.Action, got.result.Input)
		}
	})

	t.Run("ctrl+a opens start prompt and returns to workflows", func(t *testing.T) {
		model := makeModel()
		updated, _ := model.updateWorkflows("ctrl+a")
		got := updated.(*paletteModel)

		if got.state.Mode != paletteModePrompt {
			t.Fatalf("expected prompt mode, got %v", got.state.Mode)
		}
		if got.state.PromptKind != palettePromptStartFlow {
			t.Fatalf("expected start-flow prompt, got %v", got.state.PromptKind)
		}
		if got.state.PromptReturnMode != paletteModeWorkflows {
			t.Fatalf("expected prompt to return to workflows, got %v", got.state.PromptReturnMode)
		}
	})

	t.Run("ctrl+d opens destroy confirm for selected workflow", func(t *testing.T) {
		model := makeModel()
		updated, _ := model.updateWorkflows("ctrl+d")
		got := updated.(*paletteModel)

		if got.state.Mode != paletteModeConfirmDestroy {
			t.Fatalf("expected confirm-destroy mode, got %v", got.state.Mode)
		}
		if got.state.ConfirmBranch != "feature/old" || got.state.ConfirmRepoRoot != "/tmp/repo" {
			t.Fatalf("expected selected workflow destroy target, got branch=%q repo=%q", got.state.ConfirmBranch, got.state.ConfirmRepoRoot)
		}
		if got.state.ConfirmReturnMode != paletteModeWorkflows {
			t.Fatalf("expected confirm to return to workflows, got %v", got.state.ConfirmReturnMode)
		}
	})
}

func TestPaletteReloadTmuxConfigUsesHomeTmuxConf(t *testing.T) {
	t.Setenv("HOME", "/tmp/test-home")

	originalRunner := paletteTmuxRunner
	defer func() {
		paletteTmuxRunner = originalRunner
	}()

	var got []string
	paletteTmuxRunner = func(args ...string) error {
		got = append([]string(nil), args...)
		return nil
	}

	runtime := &paletteRuntime{}
	retry, _, err := runtime.execute(paletteResult{
		Kind:   paletteResultRunAction,
		Action: paletteAction{Kind: paletteActionReloadTmuxConfig},
	})
	if err != nil {
		t.Fatalf("expected no error, got %v", err)
	}
	if retry {
		t.Fatalf("did not expect retry for successful reload")
	}

	want := []string{"source-file", "/tmp/test-home/.tmux.conf"}
	if len(got) != len(want) {
		t.Fatalf("expected args %#v, got %#v", want, got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Fatalf("expected args %#v, got %#v", want, got)
		}
	}
}
