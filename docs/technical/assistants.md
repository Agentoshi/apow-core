# Personal Assistant Mining Guide

Research checked **6 October 2026**. These instructions distinguish documented platform features from APoW test reports. A cloud VM, a saved conversation, and a background task each have different lifetimes.

## Start with Easy Mode

Easy Mode uses wallet-paid RPC, an LLM for rig minting, and remote GPU grinding. The runner still detects rigs, obtains work, signs transactions, and checks receipts. Running that runner does not require a local GPU. Do not rent a VPS or switch to local CPU mining as part of normal setup.

Use the [mining skill](../skill.md) for the approved command and version. Deposit **Base ETH only** with the ETH-only CLI release. The CLI quotes the live rig fee, an ETH reserve, swap gas, and the USDC service budget, then converts the required ETH to USDC. The reserve is not the actual fee per transaction. Do not translate a dollar budget into a fixed ETH amount without a current quote.

The existing web mining app signs in the browser and needs its tab open. Fully managed background mining is under development; do not claim it is available. Once it passes its release checks, personal assistants will control the same managed jobs as the website, without storing wallet keys or managing servers. See [managed cloud mining](managed-mining.md).

## One setup, one wallet

1. Check the runtime: Node 20 or later, outbound HTTPS, writable persistent storage, and a permitted background runner. Check the platform's current terms before running mining software.
2. Use one isolated working directory and one dedicated wallet. Preserve its address across retries. If an existing wallet is locked, repair the unlock; do not create a replacement.
3. Store the encrypted keystore on persistent storage. Store the password separately in a supported secret manager. For a headless runner, save a `KEYSTORE_PASSWORD_CMD` reference in its private `.env`. Do not save the password itself there or in chat, logs, shell history, screenshots, or agent memory.
4. Run the CLI recovery check. It must unlock the same address in a fresh process. The user must also keep an independent encrypted-keystore backup and its password separately. A fresh-process check proves neither off-host backup nor survival of a VM rebuild.
5. Obtain the single-asset funding quote. Give the user one complete address, chain, asset, and amount. Resume with that same wallet after deposit. Do not ask for a separate USDC deposit.
6. Start exactly one runner for the wallet. Verify a process handle and recent logs. Report setup, funded, rig minted, runner started, and first confirmed mine as distinct states. A health response or a GPU request is not a confirmed mine.
7. Keep enforcement and the agreed limits. Pause on an unknown payment or transaction result until it is reconciled. Do not enable CPU fallback, raise caps, top up, rent a host, or grant broader access without the user's instruction.

The default x402 limits are not a complete USD loss cap: mint value, Base gas, swaps, exchange-rate changes, and hosting are separate. Set a finite test duration and reserve appropriate to the approved budget. Do not promise a hard dollar stop from an untested watcher.

## Assistant profiles

### Grok Bot

Grok Bot provides a persistent cloud computer with terminal, files, and browser. Bots belonging to the same user share that computer. Recreating the computer preserves its durable disk, but manually installed packages can need reinstalling. Background routines are available; they do not prove that an arbitrary miner daemon survives every lifecycle event. [Overview](https://docs.x.ai/grok-bot/overview), [computers](https://docs.x.ai/grok-bot/computers), [routines](https://docs.x.ai/grok-bot/skills-routines-and-automations).

Instruction: use Easy Mode in a dedicated persistent directory; check for another running APoW process before starting. Save the package version and non-secret paths. Test unlock and process restart before funding. Use a routine to inspect status, not to launch duplicate miners. Reinstall the pinned CLI after a rebuild if needed.

### Muse

Meta documents a dedicated Secure VM and a separate Sentinel that checks external actions. Protected website credentials can be used without exposing them to Muse. Public documentation does not establish that this credential store can return a keystore password to a Node process. [Meta introduction](https://about.fb.com/news/2026/09/introducing-muse-personal-ai-agent/).

Instruction: use Easy Mode. Do not assume a browser login vault is a CLI secret manager. Require a supported unlock method and persistent storage before offering a funding address. If unavailable, use an already approved host or wait for APoW managed jobs. A user-reported trial achieved confirmed local mines, but required steering, password recovery, and slow CPU work. Treat that as a bounded novelty test, not an unattended service guarantee.

### Instinct

Instinct describes an assistant reached by phone and computer; its public site does not specify durable Node services or a CLI secret interface. In a supplied test conversation, the assistant reported that its vault fills web forms but cannot unlock a miner, and that its workspace can be rebuilt. Those are observations from that session, not independently verified platform guarantees. [Instinct](https://instinct.com/).

Instruction: first test shell, secret injection, and runner lifetime. Use Easy Mode when supported. An encrypted backup alone cannot make an unavailable signing runtime work. Do not redirect the user to local CPU mining or rent a server by default. For the planned managed service, request only user-approved job access; leave wallet ownership and signing permission in the APoW user flow.

### Wajo / Fo

Wajo presents Fo as a personal assistant with human support. Its public site does not document an unrestricted shell, miner daemon lifetime, or CLI secret injection. [Wajo](https://wajo.ai/).

Instruction: check capabilities before installation. Never send wallet secrets to the assistant or a human support operator. Use Easy Mode only on a supported, approved runner. If the workspace cannot run it, report that limit and use the managed-service flow when available. Browser automation capability alone is not mining compatibility.

### OpenClaw

OpenClaw has execution tools and background process handles. `yieldMs` controls when a tool returns, while `timeoutSeconds` controls process lifetime; `timeoutSeconds: 0` disables that timeout. Processes remain subject to the selected host and sandbox lifecycle. [Exec](https://docs.openclaw.ai/tools/exec), [skills](https://docs.openclaw.ai/tools/skills).

Instruction: install the skill in the intended workspace. Use the existing approved host, Easy Mode, and the execution tool's background option. Set an appropriate process timeout and record the returned session handle. Verify with the process tool. Do not infer durability from a PID, use another agent's wallet, or bypass a host restriction.

### Hermes

Hermes provides terminal and process tools with configurable execution backends. A background process started by a delegated child may be terminated when that child ends. [Tools](https://hermes-agent.nousresearch.com/docs/user-guide/features/tools/), [delegation](https://hermes-agent.nousresearch.com/docs/user-guide/features/delegation).

Instruction: check the active terminal backend. Start the miner from the parent agent on the intended host, not a short-lived delegated agent. Use Easy Mode, persistent storage, and a secret-manager unlock reference. For unattended operation, use the host's existing service manager and verify a restart. Do not copy provider or wallet credentials between profiles.

### Claude Code

Claude Code can run Bash tasks in the background and return a task ID. That facility allows the conversation to continue; it is not a promise of a permanent operating-system service. [Background tasks](https://code.claude.com/docs/en/interactive-mode), [skills](https://code.claude.com/docs/en/skills).

Instruction: use the local trusted terminal for password entry or a supported secret store. Run Easy Mode and record the background task ID. For continued mining after Claude Code exits, use an approved service manager on the same host. Keep subscription LLM configuration optional; Easy Mode already handles the mint LLM.

### Codex

Local Codex runs on the selected computer. Each current cloud task has its own isolated VM and saved state; public documentation describes coding-task continuation and finite state retention, not a permanent miner service. Network secrets substituted into HTTPS requests are not raw credentials available to local Node processes. [CLI](https://learn.chatgpt.com/docs/codex/cli), [cloud environments](https://learn.chatgpt.com/docs/environments/cloud-environments).

Instruction: distinguish local and cloud execution. On local, use Easy Mode with the host's supported secret manager. In cloud, check network access and environment-variable secret delivery explicitly; do not assume a network secret can unlock a keystore. Keep recovery material out of repository commits and published environment snapshots. Use a durable approved runner or managed APoW jobs for unattended mining.

### Manus

Manus documents isolated task sandboxes and a separate persistent Cloud Computer product. A task sandbox must not be treated as equivalent to an always-on computer. [Sandbox](https://manus.im/blog/manus-sandbox), [Cloud Computer](https://manus.im/blog/manus-cloud-computer).

Instruction: use Easy Mode. Identify which runtime is active, and verify its storage, unlock, and process lifetime. Use an existing approved persistent computer only if its terms permit the workload. Do not purchase an upgrade or server automatically. Scheduled tasks should check a known runner rather than repeatedly create wallets or miners.

### Claude Cowork

Cowork cloud work can continue after the desktop app closes. Actions on the local computer still depend on that computer being available. Neither fact alone establishes an unattended shell miner. [Cowork](https://support.claude.com/en/articles/13345190-get-started-with-claude-cowork).

Instruction: determine whether execution is local or cloud. Use Easy Mode only if shell execution and secure unlock are supported. Keep a local host awake for local signing. Prefer approved managed job control over copying wallet secrets into a task VM.

### Perplexity Computer / Personal Computer

Personal Computer connects an assistant to a user's own computer. Cloud Computer work uses a different environment. Availability of one does not establish the other's storage or daemon guarantees. [Personal Computer](https://www.perplexity.ai/personal-computer), [Computer](https://www.perplexity.ai/en-GB/hub/blog/computer-for-enterprise).

Instruction: use the existing approved computer, Easy Mode, and a host-local secret manager. Verify the host remains on and the miner survives the agent turn. If only a temporary cloud task is available, use the same capability checks as other cloud assistants.

## Optional local mining

Local CPU mining remains an explicit experiment. In Advanced Mode, disable remote grinding with `USE_X402_GRIND=false`; choose a supported native CPU grinder or JS workers. RPC and mint LLM choices are separate. No USDC is needed only when all selected paid services are off.

Measure local hashrate, live target, rig hashpower, work changes, and confirmed receipts. Low network activity can make a slow sandbox viable, but it does not guarantee low difficulty or a reward. A successful quiet-network trial does not predict results under competition. Never enable fallback silently after a remote service failure.

## Hosting terms

An owned, already running computer avoids a new hosting subscription. Check both the assistant's and host's rules; offloading hashes does not automatically exempt a signing runner from a mining restriction. Do not recommend a free tier as a workaround.

[Contabo](https://contabo.com/blog/can-i-use-contabo-servers-for-crypto/) allows mining on dedicated-resource products and prohibits it on VPS. [DigitalOcean's AUP](https://www.digitalocean.com/legal/acceptable-use-policy) requires explicit written permission. These are examples of why product-specific checks matter, not a cheapest-host recommendation. Any rental needs a current quote, separate cost approval, and an end date.
