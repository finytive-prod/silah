# Token Optimization & UI Best Practices Rules

## 1. Token Optimization Rules (Cost & Speed Efficiency)
- **Targeted Output:** Never dump whole decompiled files, raw binaries, or huge AST trees unless explicitly asked. Use selective inspection, diffing, and targeted line queries.
- **Concise Responses:** Give high-density, direct explanations without unnecessary filler text or redundant summaries.
- **Progressive Analysis:** In reverse-engineering tasks, check symbols, manifests, and component architectures first before diving into heavy disassembled/decompiled routines.
- **REA Token Caps:** Leverage REA's native `--token-limit <n>`, `--filter-output <keys>`, and targeted queries to keep context windows lean.

## 2. UI/UX Quality Guidelines (Mobile & Web)
- **Modern Design Systems:** Follow clean typography hierarchy, proper spacing grids (4px/8px), tactile micro-interactions, and accessible contrast (WCAG AA).
- **Responsive & Adaptive:** Ensure responsive mobile-first layouts, safe-area insets, dark/light theme support, and seamless edge-to-edge UI.
- **State Management & Feedback:** Provide immediate feedback on user interactions (skeleton loaders, optimistic updates, micro-animations, clear error boundaries).
