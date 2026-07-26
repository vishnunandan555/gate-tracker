# Contributing Motivational Quotes 🌟

We love community contributions! If you have a favorite motivational quote that keeps you focused, disciplined, or inspired during exam preparation, you can add it directly to GATEletics.

GATEletics uses **two quote files**, each serving a different purpose:

| File | Where it appears |
|---|---|
| `quotes.json` | Home screen / general motivational carousel |
| `focus_quotes.json` | Focus Mode timer — shown during active study & break intervals |

---

## Guidelines for All Quotes

- **Theme:** Focus on consistency, learning, persistence, engineering, problem-solving, or general positivity.
- **Length:** Keep them concise (ideally under 120 characters) so they render beautifully on all device screens.
- **Language:** Standard English.
- **No profanity or negativity.**

---

## 1. Contributing to `quotes.json` (General Quotes)

These are plain motivational strings shown on the home screen.

### Format

`quotes.json` is a flat JSON array of strings:

```json
[
  "Small daily improvements over time lead to stunning results.",
  "Your only limit is you."
]
```

### Steps

1. **Duplicate Check:** Verify your quote isn't already in `quotes.json`.
2. Open `quotes.json` and append your quote as a new string at the end of the array.
3. Make sure the JSON is valid (comma-separated entries, no trailing comma after the last item).

### Example addition

```json
[
  ...,
  "Your only limit is you.",
  "The harder you work for something, the greater you'll feel when you achieve it."
]
```

---

## 2. Contributing to `focus_quotes.json` (Focus Mode Quotes)

These quotes appear **inside an active Focus Mode session** — either during the study interval (`focus`) or during a break (`break`). They are slightly more contextual and can use **dynamic placeholders** that the app fills in at runtime.

### Structure

`focus_quotes.json` is a JSON object with two arrays:

```json
{
  "focus": [ ... ],
  "break": [ ... ]
}
```

- **`focus`** — shown while the user is actively studying.
- **`break`** — shown during a break interval.

### Dynamic Placeholders

You can optionally embed any of the following placeholders in your quote. The app will replace them with live values at runtime:

| Placeholder | Replaced with |
|---|---|
| `{user_name}` | The user's display name |
| `{elapsed_minutes}` | Minutes elapsed in the current session |
| `{remaining_minutes}` | Minutes remaining in the current interval |
| `{tasks_completed}` | Number of tasks completed this session |

**Rules for placeholders:**
- Placeholders are optional — a quote without them works perfectly fine.
- Always wrap placeholder names in curly braces exactly as shown above.
- Make sure the sentence still reads naturally if a name like "Alex" or a number like "25" is substituted in.

### Example additions

Adding a **focus** quote (with placeholder):
```json
"focus": [
  ...,
  "You've got this, {user_name}! {remaining_minutes} minutes left — make them count."
]
```

Adding a **break** quote (without placeholder):
```json
"break": [
  ...,
  "Hydrate, breathe, reset. The next session is going to be even better."
]
```

---

## Step-by-Step Contribution Guide

### 1. Fork the Repository
Click the **Fork** button at the top-right of the [GATEletics Repository](https://github.com/vishnunandan555/gateletics) to create a copy of the project in your GitHub account.

### 2. Edit the Relevant File(s)
- For general quotes → edit `quotes.json`
- For focus/break quotes → edit `focus_quotes.json`

You can edit directly on GitHub or clone your fork locally.

### 3. Open a Pull Request (PR)
1. Commit your changes with a clear message, e.g.:
   - `feat: add motivational quote to quotes.json`
   - `feat: add focus mode quote with {remaining_minutes} placeholder`
2. Push the changes to your fork.
3. Open a **Pull Request** from your fork to the `main` branch of `gateletics`.
4. We will review and merge it. Once merged, the app will automatically fetch and display your quote to all users! 🚀

---

## 🏷️ Version Strategy & Release Lifecycle

GATEletics follows a structured versioning lifecycle for release management:

- **Pre-Releases / Betas (`v1.3.0.X`)**:
  - All versions following the pattern `v1.3.0.X` (e.g. `v1.3.0.0`, `v1.3.0.1`, `v1.3.0.2`) are **pre-releases / beta builds**.
  - Published as GitHub Pre-Releases for active feature testing and community feedback.
- **Proper Stable Releases (`v1.3.X.Y`)**:
  - Proper stable releases follow the pattern `v1.3.X.Y` (where $X \ge 1$), published as full GitHub Releases and deployed for production distribution.
