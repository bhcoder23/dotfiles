import { appendFileSync, mkdirSync, readFileSync, renameSync, writeFileSync } from "fs"

const MAX_SUMMARY_CHARS = 600
const LOG_FILE = "/tmp/tracker-notify-debug.log"
const STATE_ROOT = process.env.XDG_STATE_HOME || `${process.env.HOME || ""}/.local/state`
const OP_STATE_DIR = `${STATE_ROOT}/op`
const TMUX_QUESTION_OPTION = "@op_question_pending"
const TMUX_BINS = [process.env.TMUX_BIN, "/opt/homebrew/bin/tmux", "tmux"].filter(Boolean)
const TRACKER_BINS = [
	process.env.OP_TRACKER_BIN,
	`${process.env.HOME || ""}/.config/agent-tracker/bin/agent`,
	`${process.env.HOME || ""}/.local/bin/agent`,
].filter(Boolean)

const log = (message: string, data?: unknown) => {
	const timestamp = new Date().toISOString()
	const line = `[${timestamp}] ${message}${data ? ` ${JSON.stringify(data)}` : ""}\n`
	try {
		appendFileSync(LOG_FILE, line)
	} catch {}
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

export const TrackerNotifyPlugin = async ({ client, directory, $ }) => {
	if (process.env.OP_TRACKER_NOTIFY !== "1") {
		return {}
	}

	const tmuxPane = process.env.TMUX_PANE
	log("plugin loading", { tmuxPane })
	if (!tmuxPane) {
		return {}
	}

	let tmuxContext:
		| {
				sessionId?: string
				windowId?: string
				paneId?: string
				sessionName?: string
				windowIndex?: string
				paneIndex?: string
		  }
		| null = null
	let trackerBin = ""
	let taskActive = false
	let currentSessionID = ""
	let lastUserMessage = ""
	let rootSessionID = ""
	let questionPending: boolean | null = null

	const messageRoles = new Map<string, string>()

	const sanitizeKey = (value = "") => value.replace(/[^A-Za-z0-9_]/g, "_")

	const resolveTmuxContext = async () => {
		if (tmuxContext) {
			return tmuxContext
		}

		for (const tmuxBin of TMUX_BINS) {
			try {
				const output =
					await $`${tmuxBin} display-message -p -t ${tmuxPane} "#{session_id}:::#{window_id}:::#{pane_id}:::#{session_name}:::#{window_index}:::#{pane_index}"`.text()
				const parts = output.trim().split(":::")
				if (parts.length === 6) {
					tmuxContext = {
						sessionId: parts[0],
						windowId: parts[1],
						paneId: parts[2],
						sessionName: parts[3],
						windowIndex: parts[4],
						paneIndex: parts[5],
					}
					return tmuxContext
				}
			} catch {}
		}

		tmuxContext = { paneId: tmuxPane }
		return tmuxContext
	}

	const paneLocator = () => {
		if (!tmuxContext?.sessionName || !tmuxContext.windowIndex || !tmuxContext.paneIndex) {
			return ""
		}
		return `${tmuxContext.sessionName}:${tmuxContext.windowIndex}.${tmuxContext.paneIndex}`
	}

	const paneSessionStateFile = () => {
		const locator = paneLocator()
		if (!locator) {
			return ""
		}
		return `${OP_STATE_DIR}/loc_${sanitizeKey(locator)}`
	}

	const persistPaneSessionMap = async (sessionID: string) => {
		const stateFile = paneSessionStateFile()
		if (!sessionID || !stateFile) {
			return
		}
		try {
			mkdirSync(OP_STATE_DIR, { recursive: true })
			const tmpFile = `${stateFile}.tmp`
			writeFileSync(tmpFile, `${sessionID}\n`, "utf8")
			renameSync(tmpFile, stateFile)
		} catch (error) {
			log("persist pane session failed", { stateFile, error: String(error) })
		}
	}

	const loadPersistedPaneSessionID = () => {
		const stateFile = paneSessionStateFile()
		if (!stateFile) {
			return ""
		}
		try {
			return readFileSync(stateFile, "utf8").trim()
		} catch {
			return ""
		}
	}

	const eventSessionID = (event: any) =>
		event?.properties?.sessionID ||
		event?.properties?.session?.id ||
		event?.properties?.info?.id ||
		""

	const resolveTrackerBin = async () => {
		if (trackerBin) {
			return trackerBin
		}

		for (const candidate of TRACKER_BINS) {
			const check = await $`test -x ${candidate}`.nothrow()
			if (check.exitCode === 0) {
				trackerBin = candidate
				return trackerBin
			}
		}

		return ""
	}

	const setTmuxPaneOption = async (option: string, value: string | null) => {
		await resolveTmuxContext()
		if (!tmuxContext?.paneId) {
			return
		}

		for (const tmuxBin of TMUX_BINS) {
			const proc =
				value === null
					? await $`${tmuxBin} set-option -p -u -t ${tmuxContext.paneId} ${option}`.nothrow()
					: await $`${tmuxBin} set-option -p -t ${tmuxContext.paneId} ${option} ${value}`.nothrow()
			if (proc.exitCode === 0) {
				return
			}
		}
	}

	const applyQuestionPending = async (pending: boolean) => {
		if (questionPending === pending) {
			return
		}
		questionPending = pending
		await setTmuxPaneOption(TMUX_QUESTION_OPTION, pending ? "1" : null)
	}

	const listPendingQuestions = async () => {
		try {
			const response = await client.question.list({ directory })
			if (Array.isArray(response?.data)) {
				return response.data
			}
			if (Array.isArray(response)) {
				return response
			}
		} catch {}
		return []
	}

	const syncPendingQuestionState = async (sessionID = rootSessionID) => {
		const effectiveSessionID = sessionID || loadPersistedPaneSessionID()
		if (!effectiveSessionID) {
			await applyQuestionPending(false)
			return
		}

		rootSessionID = effectiveSessionID
		const pending = (await listPendingQuestions()).some(
			(question: any) => question?.sessionID === effectiveSessionID,
		)
		await applyQuestionPending(pending)
	}

	const buildTrackerArgs = () => {
		const args: string[] = []
		if (tmuxContext?.sessionId) {
			args.push("-session-id", tmuxContext.sessionId)
		}
		if (tmuxContext?.windowId) {
			args.push("-window-id", tmuxContext.windowId)
		}
		if (tmuxContext?.paneId) {
			args.push("-pane", tmuxContext.paneId)
		}
		return args
	}

	const runTrackerCommand = async (command: string, summary = "") => {
		const bin = await resolveTrackerBin()
		if (!bin) {
			return false
		}

		const args = [bin, "tracker", "command", ...buildTrackerArgs()]
		if (summary) {
			args.push("-summary", summary)
		}
		args.push(command)

		const proc = Bun.spawn(args, {
			stdin: "ignore",
			stdout: "ignore",
			stderr: "pipe",
		})
		const [stderr, exitCode] = await Promise.all([
			new Response(proc.stderr).text(),
			proc.exited,
		])
		if (exitCode !== 0) {
			log("tracker command failed", { command, summary, exitCode, stderr: stderr.trim() })
			return false
		}
		return true
	}

	const summarizeText = (parts: any[] = []) =>
		parts
			.filter((part) => part?.type === "text" && !part?.ignored)
			.map((part) => part?.text || "")
			.join("\n")
			.trim()
			.slice(0, MAX_SUMMARY_CHARS)

	const getLastMessageText = async (sessionID: string, role: string, retries = 3) => {
		for (let attempt = 0; attempt < retries; attempt += 1) {
			try {
				const messages =
					(await client.session.messages({
						path: { id: sessionID },
						query: { directory },
					})) || []
				const message = [...messages].reverse().find((item: any) => item?.info?.role === role)
				if (message) {
					const text = summarizeText(message.parts)
					if (text) {
						return text
					}
				}
			} catch {}

			if (attempt < retries - 1) {
				await sleep(100)
			}
		}

		return ""
	}

	const startTask = async (summary: string, sessionID: string) => {
		if (!summary) {
			return
		}
		const started = await runTrackerCommand("start_task", summary)
		if (!started) {
			return
		}
		taskActive = true
		currentSessionID = sessionID
	}

	const finishTask = async (summary: string) => {
		if (!taskActive) {
			return
		}
		const finished = await runTrackerCommand("finish_task", summary || "done")
		if (!finished) {
			return
		}
		taskActive = false
		currentSessionID = ""
	}

	await resolveTmuxContext()
	rootSessionID = loadPersistedPaneSessionID()
	await syncPendingQuestionState(rootSessionID)

	return {
		"tool.execute.before": async (input: any, output: any) => {
			if (input.tool !== "question") {
				return
			}

			if (!rootSessionID && input?.sessionID) {
				rootSessionID = input.sessionID
			}
			await applyQuestionPending(true)
			log("question tool called", {
				questions: output.args?.questions || "no questions",
			})
		},

		event: async ({ event }: any) => {
			if (event?.type === "question.asked") {
				await applyQuestionPending(true)
				return
			}

			if (event?.type === "question.replied" || event?.type === "question.rejected") {
				await syncPendingQuestionState(event?.properties?.sessionID || rootSessionID)
				return
			}

			if (event?.type === "message.updated") {
				const info = event?.properties?.info
				if (info?.id && info?.role) {
					messageRoles.set(info.id, info.role)
				}
			}

			if (event?.type === "message.part.updated") {
				const part = event?.properties?.part
				if (part?.type === "text" && part?.text && part?.messageID) {
					const role = messageRoles.get(part.messageID)
					if (role === "user" || (!role && !taskActive)) {
						const text = part.text.trim()
						if (text) {
							lastUserMessage = text.slice(0, MAX_SUMMARY_CHARS)
						}
					}
				}
			}

			if (event?.type !== "session.updated" && event?.type !== "session.status") {
				return
			}

			const sessionID = eventSessionID(event)
			if (!sessionID) {
				return
			}

			const session = await client.session.get({ path: { id: sessionID } }).catch(() => null)
			if (session?.data?.parentID) {
				return
			}

			const sessionChanged = sessionID !== rootSessionID
			rootSessionID = sessionID
			await persistPaneSessionMap(sessionID)
			if (sessionChanged) {
				await syncPendingQuestionState(sessionID)
			}

			if (event?.type !== "session.status") {
				return
			}

			const status = event?.properties?.status
			if (!status) {
				return
			}

			if (status.type === "busy" && !taskActive) {
				let text = lastUserMessage
				if (!text) {
					text = await getLastMessageText(sessionID, "user")
				}
				await startTask(text || "working...", sessionID)
				lastUserMessage = ""
				return
			}

			if (status.type === "idle" && taskActive) {
				if (currentSessionID && sessionID !== currentSessionID) {
					return
				}
				const text = await getLastMessageText(sessionID, "assistant")
				await finishTask(text || "done")
			}
		},
	}
}
