# SkillDeck

A macOS app for managing AI agent skills across multiple platforms including OpenClaw, Claude Code, Cursor, Windsurf, Codex, and Aider.

![SkillDeck](.github/screenshot.png)

## Features

- **Multi-Agent Support**: Scan and manage skills from OpenClaw, Claude Code, Cursor, Windsurf, Codex, Aider, and more
- **Skill Auditing**: Automatically scan skills for safety issues and upgrade suggestions
- **Risk Assessment**: Visual risk indicators for each skill (Low/Medium/High)
- **Quick Actions**: Show in Finder, Upgrade, and Delete skills directly from the app
- **Native macOS**: Built with SwiftUI using NavigationSplitView for a native experience

## Supported Agents

| Agent | Skills Location |
|-------|----------------|
| OpenClaw | `~/.openclaw/skills` |
| Claude Code | `~/.claude/skills` |
| Cursor | `~/.cursor/skills` |
| Windsurf | `~/.windsurf/skills` |
| Codex | `~/.codex/skills` or `$CODEX_HOME/skills` |
| Aider | `~/.aider/skills` |
| Workspace | `./skill` (discovered from project tree) |

## Installation

### Build from Source

```bash
git clone https://github.com/pythias/ai-skill-deck.git
cd ai-skill-deck
swift build
swift run
```

### Build App Bundle

```bash
xcodebuild -scheme SkillDeck -configuration Release build
```

The `.app` bundle will be in `~/Library/Developer/Xcode/DerivedData/`.

## Usage

1. Launch SkillDeck
2. Skills are automatically scanned from all known agent locations
3. Select a skill in the sidebar to view details
4. Use "Show in Finder" to locate the skill on disk
5. Use "Upgrade" to replace a skill with a newer version
6. Use "Delete" to remove a skill (with confirmation)

## Safety Audit

SkillDeck automatically scans skills for:
- Destructive shell patterns (`rm -rf`)
- Pipe-to-shell patterns (`curl | sh`, `wget | sh`)
- Privilege escalation attempts (`sudo`)
- AppleScript automation
- Subprocess execution
- Network requests

## License

MIT License - see [LICENSE](LICENSE) for details.
