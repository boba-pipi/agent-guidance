---
name: learn
description: Teach a topic, concept, codebase, or change through visuals and concrete examples that help the reader predict how it behaves. Use for a message beginning with "learn" followed by a topic, or when the user wants to understand how or why something works.
---

# Learn

Use everything after `learn` (or the host's explicit skill invocation) as the topic. Start with the user's concrete question, a familiar example, or an observable outcome. For a broad topic, give a small orienting view and zoom into the part that explains the question. Explain in the user's language. Ask only if missing context would change the explanation materially.

## Make the mechanism visible

- Place a useful visual near the point it explains. Use the format the user asks for. If the user asks for ImageGen, call the built-in tool when available.
- When the user leaves the format open, choose a specialized visual only if it teaches the point more clearly or accurately. Use a flowchart or sequence diagram when the key information is the order of calls, branches, or states. Use a plot when measured values matter, an actual screenshot when the real UI matters, or an interactive model when varying an input helps the reader see what changes.
- Otherwise, if a visual helps, use the built-in ImageGen tool when available. It is the default for an open-ended teaching visual, including software concepts. Choose an illustration, storyboard, cutaway, or comparison that shows the mechanism. Show the image inline. If ImageGen is unavailable, use the best format the host can render.
- Check that visuals preserve the relevant relationships and conditions. Use short labels on the visual and put long identifiers, exact expressions, and source links in the caption. Break a flow at a meaningful boundary when reading it would otherwise require repeatedly scrolling back to its start. Mark generated illustrations as conceptual when readers could mistake them for screenshots or observations. Label arrows and units when their meaning matters and pair colors with text or shape.

## Build a model the reader can use

- Walk through one concrete case with the visual. Show what starts the behavior, where decisions happen, what changes, and what the reader would see. Introduce terms at their first use. Preserve the conditions, timing, and exceptions that would change the outcome. Put secondary details after the main explanation.
- Where it helps, change one meaningful condition or compare one realistic alternative using the same scenario. Explain why the result changes. A reader should be able to apply the rule to a nearby case without memorizing the example.
- For projects, use current source, relevant configuration, and tests or observed behavior. Link to the best starting points. When covering a diff, compare the same scenario across both versions. Use history or design notes for stated rationale and label inferred rationale or hypothetical behavior accordingly. Say when verification matters and whether it was performed.
- Teach in chat by default. Keep project inspection read-only unless the user requests changes.
