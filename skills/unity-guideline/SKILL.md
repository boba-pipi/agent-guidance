---
name: unity-guideline
description: Design, write, or review Unity gameplay, components, Editor tools, and tests. Use for Unity lifecycle, scene and Prefab wiring, serialization, input, physics, assets, and measured runtime performance. Pair with csharp-guidelines for C# conventions.
---

# Unity Guidelines

Follow project rules and apply `csharp-guidelines` for C# style and naming. Use this skill for behavior governed by the Unity engine. Read `ProjectSettings/ProjectVersion.txt`, `Packages/manifest.json`, and the package lockfile before choosing version-sensitive APIs. Check the target platform, scripting backend, and relevant project settings when they can change behavior. Inspect affected scenes, Prefabs, assets, and tests as well as scripts.

## Components and ownership

- Give each component a clear responsibility and lifetime. Let scene and Prefab components own their Unity references, lifecycle, and presentation. Keep rules that can be expressed independently of the engine in plain C# when that makes callers and tests simpler. Add an interface or assembly boundary when it isolates a real dependency.
- Use Inspector references or a local component lookup for scene wiring. Use `[RequireComponent]` for a component that must be on the same GameObject and check existing Prefabs when adding a requirement. Assemble cross-object dependencies where their lifetime is known. Validate required wiring at its boundary and identify the owning component and missing dependency.
- Keep authored shared data, such as a weapon definition, in assets when it needs Inspector editing or reuse. Keep health, cooldowns, temporary selections, and other instance state with the runtime owner. Give explicitly shared runtime state a reset and teardown policy.
- Keep Editor-only APIs and tests in the appropriate assemblies. Follow the existing assembly dependency direction and keep runtime code free of `UnityEditor` references. Add assembly definitions when they enforce a meaningful boundary or enable the needed test assembly.

## Lifecycle and time

- Initialize owned references and state at the appropriate lifecycle entry point, often `Awake`. Pair subscriptions with their lifetime, such as `OnEnable` and `OnDisable` for active-only listeners. Give dynamically spawned dependencies an explicit setup order. Use project-wide script execution order only for a deliberate ordering dependency.
- Test re-enable, despawn or scene changes when a component owns subscriptions or deferred work. With Domain Reload disabled, explicitly reset any static state and static handlers that must start fresh. For Unity object references that can be destroyed, use Unity's null check before accessing the object.
- Choose the clock that owns the rule. Capture input edges in the phase configured by the project's input system. Buffer them for fixed-step consumers and consume once. With default fixed-step physics, apply physics-driven movement and forces in `FixedUpdate` through the relevant 2D or 3D Rigidbody API. Use the render-frame loop for presentation and unscaled time for work that should continue while gameplay is paused.
- Tie coroutines, asynchronous work, and resource handles to their owning object, scene, or session. Cancel or disregard stale work after teardown. Use `destroyCancellationToken` where available for destroy-bound work. Return to the main thread before calling Unity APIs that require it. If using Addressables, pair each load or instance with its corresponding release.

## Serialization and assets

- Prefer `[SerializeField] private` for Inspector data using the project's C# naming conventions. Store editable data in fields supported by Unity serialization. Use `[SerializeReference]` when the persisted model needs managed reference identity or polymorphism, and account for compatibility if a serialized type moves or changes.
- Treat field names and asset identities as persisted contracts. Apply `[FormerlySerializedAs]` when renaming a serialized field and verify a value authored before the rename. Move or rename assets with their `.meta` files to preserve GUIDs. Inspect Prefab overrides and scene references before deleting or replacing shared components or assets.
- Use `OnValidate` for local data validation. Put object creation and Editor actions in explicit tools or callbacks suited to that work. Include the affected `.meta`, scene, Prefab, or settings files required by the change.

## Tests and performance

- Use `test-design` to choose cases by risk. Use Edit Mode for pure gameplay rules, asset checks, and Editor tooling. Use Play Mode for runtime wiring, lifecycle, input, physics, and behavior exercised across frames. Build or run a target player when platform, loading, or scripting-backend behavior is part of the contract. Use deterministic fixtures and wait for the relevant event or tick.
- For example, verify in Edit Mode that a required animation event is present in its clip. In Play Mode, play the animation with the real Prefab wiring and verify the event causes the intended effect once. Test pure damage rules separately when they can run without Unity.
- Use `performance-optimization` for scene loading, rendering, UI, and end-to-end frame cost. Use `perf-engineering` when a profile points to CPU work, allocations, memory, or scaling within a measured path. Profile a repeatable scene on representative hardware in a Development Player. Compare frame time and the relevant CPU, GPU, physics, or GC metric before and after under the same conditions.
- Fix the measured cause first. Cache repeated lookups or reuse buffers in proven hot paths. Pool frequently created objects when creation or GC pressure warrants it, and reset state, timers, and subscriptions when reusing them. Adopt Jobs, Burst, or ECS when the measured workload and project's architecture justify it.

## Unity references

- [Event execution order](https://docs.unity3d.com/6000.0/Documentation/Manual/execution-order.html), [Domain Reload](https://docs.unity3d.com/6000.0/Documentation/Manual/domain-reloading.html), [Input System settings](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/Settings.html), and [Unity physics performance](https://unity.com/how-to/enhanced-physics-performance-smooth-gameplay).
- [Serialization rules](https://docs.unity3d.com/6000.0/Documentation/Manual/script-serialization-rules.html), [serialized field renames](https://docs.unity3d.com/6000.0/Documentation/ScriptReference/Serialization.FormerlySerializedAsAttribute.html), [asset metadata](https://docs.unity3d.com/6000.0/Documentation/Manual/AssetMetadata.html), and [Prefab assets](https://docs.unity3d.com/6000.0/Documentation/Manual/Prefabs.html).
- [ScriptableObject](https://docs.unity3d.com/6000.0/Documentation/Manual/class-ScriptableObject.html), [RequireComponent](https://docs.unity3d.com/6000.0/Documentation/ScriptReference/RequireComponent.html), [OnValidate](https://docs.unity3d.com/6000.0/Documentation/ScriptReference/MonoBehaviour.OnValidate.html), and [assembly definitions](https://docs.unity.com/en-us/engine/6000.0/manual/programming-environment/script-compilation/assembly-definition-files/assembly-definitions-creating).
- [Awaitable continuations](https://docs.unity3d.com/6000.0/Documentation/Manual/async-awaitable-continuations.html), [destroyCancellationToken](https://docs.unity3d.com/6000.0/Documentation/ScriptReference/MonoBehaviour-destroyCancellationToken.html), and [Addressables memory management](https://docs.unity3d.com/Packages/com.unity.addressables@2.7/manual/MemoryManagement.html).
- [Unity Test Framework modes](https://docs.unity3d.com/Packages/com.unity.test-framework@1.4/manual/edit-mode-vs-play-mode-tests.html), [profiling applications](https://docs.unity3d.com/6000.0/Documentation/Manual/profiler-profiling-applications.html), and [pooling and reusing objects](https://docs.unity.com/en-us/engine/6000.6/manual/analysis/performance-memory/managed-memory/optimizing-code-managed-memory/reusable-code).
