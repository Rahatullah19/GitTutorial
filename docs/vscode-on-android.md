# Using VS Code on an Android phone

There is **no official VS Code app for Android**. Microsoft does not publish one,
and anything on the Play Store calling itself "VS Code" is not from Microsoft.

What does work are three real options. They are listed easiest-first — pick the
one that matches what you actually need.

| | Option | Setup time | Terminal? | Works offline? |
|---|---|---|---|---|
| 1 | `github.dev` in the browser | ~0 min | No | No |
| 2 | Remote Tunnel to a real computer | ~5 min | Yes | No |
| 3 | `code-server` locally via Termux | ~20 min | Yes | Yes |

---

## Option 1 — github.dev (fastest, zero install)

The quickest way to edit this repository from the phone. It is the real VS Code
editor running in the browser, backed by the GitHub repo.

1. Open Chrome on the phone.
2. Go to **<https://github.dev/rahatullah19/gittutorial>**

   (Equivalently: open the repo on github.com and press `.` — or swap `github.com`
   for `github.dev` in any repo URL.)
3. Sign in to GitHub when prompted.
4. Edit files. Use the **Source Control** panel in the left sidebar to commit and
   push — it commits straight to the branch you have checked out.

**What you get:** the editor, syntax highlighting, search, Git commit/push, and
most extensions that are pure-UI (themes, language grammars).

**What you don't get:** a terminal, running/debugging code, or any extension that
needs to execute something (linters, test runners, language servers like Pylance).
There is no compute behind it — it is an editor, not a machine.

> Tip: add it to your home screen (Chrome menu → *Add to Home screen*) so it opens
> without the browser chrome and gets more vertical space.

---

## Option 2 — Remote Tunnel to a computer you already own

If you have a laptop or desktop that is switched on, this gives you the **full**
VS Code experience on the phone — terminal, extensions, debugging — because the
code actually runs on that machine. This is Microsoft's own feature.

**On the computer** (once):

```sh
# If VS Code is installed, its CLI is already on your PATH.
code tunnel
```

The first run asks you to authenticate with GitHub or Microsoft and to name the
tunnel. Leave the command running (or install it as a service with
`code tunnel service install` so it survives reboots).

**On the phone:**

1. Open <https://vscode.dev> in Chrome.
2. Sign in with the same account.
3. Pick your tunnel from the remote list — or go straight to
   `https://vscode.dev/tunnel/<your-tunnel-name>`.

You are now editing files on the computer, from the phone, with a working
integrated terminal.

**Caveat:** the computer has to be awake and online. Check its sleep settings.

---

## Option 3 — code-server locally via Termux (fully self-contained)

Runs a VS Code server *on the phone itself*. Nothing else needs to be online.
This is the heaviest option: expect ~2 GB of storage and a slower experience, but
you get a genuine Linux environment with a terminal, `git`, `node`, `python`, and
real extensions.

### Step 1 — Install Termux (not from the Play Store)

The Play Store build of Termux is **abandoned and broken** on modern Android.
Install from one of these instead:

- **F-Droid:** <https://f-droid.org/packages/com.termux/>
- **GitHub releases:** <https://github.com/termux/termux-app/releases>
  (pick the `universal` APK if unsure)

You will need to allow installing from unknown sources when prompted.

### Step 2 — Stop Android from killing it

Android aggressively kills background apps, which will stop code-server mid-use.

- Android **Settings → Apps → Termux → Battery → Unrestricted**
  (wording varies by manufacturer; on Samsung/Xiaomi/OnePlus look for
  "Don't optimise", "No restrictions", or "Allow background activity").

### Step 3 — Run the installer

Open Termux and paste this in:

```sh
pkg install -y git
git clone https://github.com/rahatullah19/gittutorial.git
bash gittutorial/scripts/setup-code-server-android.sh
```

The script installs a Debian/Ubuntu environment inside Termux via `proot-distro`,
installs `code-server` into it, generates a random password, and creates a
`code-server-start` launcher command.

It takes 10–25 minutes depending on your connection and phone. It is safe to
re-run — it skips anything already done and will not change your password.

### Step 4 — Start it and connect

In Termux:

```sh
code-server-start
```

Then open **<http://localhost:8080>** in Chrome on the same phone and enter the
password the script printed. To see the password again:

```sh
proot-distro login ubuntu -- cat /root/.config/code-server/config.yaml
```

Leave the Termux notification alone while you work — swiping it away kills the
server. To stop cleanly, return to Termux and press `Ctrl+C`.

---

## Making any of these usable on a touchscreen

A phone keyboard has no `Ctrl`, `Esc`, `Tab`, or arrow keys, which makes an editor
painful. Fix that first:

- **Install a developer keyboard.** [Hacker's Keyboard](https://f-droid.org/packages/org.pocketworkstation.pckeyboard/)
  gives you a full PC layout including `Ctrl`, `Alt`, `Esc` and function keys.
  This single change matters more than anything else on this page.
- **A cheap Bluetooth or USB-C keyboard** turns the phone into a genuinely workable
  machine. If you are going to do this regularly, get one.
- **Request desktop site** in the Chrome menu if the layout renders as mobile.
- **Rotate to landscape** — the file tree and editor need the width.
- In Termux, the volume-down key acts as `Ctrl` (e.g. `Vol-Down` + `C` = `Ctrl+C`),
  and swiping up from the keyboard area reveals an extra-keys row.

## Which should you pick?

- Just editing this tutorial repo and pushing commits → **Option 1**. Open the
  link, done.
- You own a computer that is usually on → **Option 2**. Best experience by far.
- You want a real dev environment with no other machine involved → **Option 3**.

## Known limitations

- Whatever you pick, this is a small screen. It is good for edits, reviews, and
  quick fixes; it is not a replacement for a desktop for sustained work.
- Option 3 on 32-bit ARM devices will be slow, because `code-server` has no
  prebuilt binary for `armv7` and falls back to compiling from source. Almost all
  phones from the last several years are 64-bit (`arm64`) and unaffected — check
  with `uname -m` in Termux.
- Extensions that ship native binaries compiled for desktop (some debuggers) may
  not work under Options 1 or 3.
