---
name: r3f-best-practices
description: React Three Fiber and Poimandres ecosystem best practices. 60+ rules across 11 categories. Use when building 3D web experiences with R3F, drei, zustand, rapier, or postprocessing.
license: MIT
metadata:
  author: emalorenzo
  source: https://github.com/emalorenzo/three-agent-skills
  version: "1.0.0"
---

# React Three Fiber Best Practices

Comprehensive optimization guide for R3F and the Poimandres ecosystem. 60+ rules prioritized by impact.

## When to Apply

Reference these guidelines when:
- Creating new R3F components
- Optimizing 3D scene performance
- Implementing animations with useFrame
- Managing state with Zustand
- Adding physics or post-processing
- Debugging performance issues

### Remotion Exception

When using R3F with **Remotion** (video rendering), see `/remotion-best-practices` instead for animation rules. Key difference:
- **Standard R3F**: Use `useFrame()` for animations
- **Remotion**: `useFrame()` is FORBIDDEN - use `useCurrentFrame()` instead

## Rule Categories by Priority

| Priority | Category | Impact | Prefix |
|----------|----------|--------|--------|
| 1 | Performance & Re-renders | CRITICAL | `perf-` |
| 2 | useFrame & Animation | CRITICAL | `frame-` |
| 3 | Component Patterns | HIGH | `component-` |
| 4 | Canvas & Setup | HIGH | `canvas-` |
| 5 | Drei Helpers | MEDIUM-HIGH | `drei-` |
| 6 | Loading & Suspense | MEDIUM-HIGH | `loading-` |
| 7 | State Management | MEDIUM | `state-` |
| 8 | Events & Interaction | MEDIUM | `events-` |
| 9 | Post-processing | MEDIUM | `postpro-` |
| 10 | Physics (Rapier) | LOW-MEDIUM | `physics-` |

---

## 1. Performance & Re-renders (CRITICAL)

The #1 killer in R3F is React reconciliation at 60fps.

### perf-no-setstate-useframe

**NEVER call setState inside useFrame** - causes 60 re-renders/second.

```tsx
// BAD - 60 re-renders per second
function BadComponent() {
  const [position, setPosition] = useState(0)
  useFrame(() => {
    setPosition(p => p + 0.01) // Triggers re-render every frame
  })
  return <mesh position-x={position} />
}

// GOOD - Zero re-renders
function GoodComponent() {
  const meshRef = useRef<Mesh>(null)
  useFrame(() => {
    if (meshRef.current) {
      meshRef.current.position.x += 0.01
    }
  })
  return <mesh ref={meshRef} />
}
```

### perf-isolate-stateful

Isolate stateful components from 3D objects:

```tsx
// BAD - Parent re-renders affect mesh
function Scene() {
  const [score, setScore] = useState(0)
  return (
    <>
      <ScoreDisplay score={score} />
      <mesh /> {/* Re-renders when score changes */}
    </>
  )
}

// GOOD - Isolated re-renders
function Scene() {
  return (
    <>
      <ScoreContainer /> {/* Contains its own state */}
      <mesh /> {/* Never re-renders */}
    </>
  )
}
```

### perf-zustand-selectors

Use Zustand selectors for granular subscriptions:

```tsx
// BAD - Re-renders on ANY store change
const store = useGameStore()

// GOOD - Re-renders only when score changes
const score = useGameStore(state => state.score)
```

### perf-memoize-expensive

Memoize expensive components:

```tsx
const ExpensiveMesh = memo(function ExpensiveMesh({ geometry }) {
  return <mesh geometry={geometry} />
})
```

### perf-stable-keys

Use stable keys for dynamic lists:

```tsx
// BAD - Index keys cause recreation
{items.map((item, i) => <Mesh key={i} {...item} />)}

// GOOD - Stable identity keys
{items.map(item => <Mesh key={item.id} {...item} />)}
```

---

## 2. useFrame & Animation (CRITICAL)

### frame-use-delta

Always use delta time for frame-rate independence:

```tsx
useFrame((state, delta) => {
  // Consistent speed regardless of frame rate
  mesh.current.rotation.y += delta * speed
})
```

### frame-priority

Implement priority ordering for execution sequence:

```tsx
// Lower numbers run first
useFrame(() => { /* physics */ }, -1)
useFrame(() => { /* rendering */ }, 0)
useFrame(() => { /* UI sync */ }, 1)
```

### frame-conditional

Disable useFrame conditionally:

```tsx
// null priority = disabled
useFrame(() => {
  // Animation logic
}, isAnimating ? 0 : null)
```

### frame-getstate

Access state without re-renders in useFrame:

```tsx
useFrame(() => {
  // Direct access, no subscription
  const { player } = useGameStore.getState()
  mesh.current.position.copy(player.position)
})
```

### frame-invalidate

Use invalidate() for on-demand rendering:

```tsx
function StaticScene() {
  const invalidate = useThree(state => state.invalidate)

  const handleChange = () => {
    // Only render when something changes
    invalidate()
  }
}
```

---

## 3. Component Patterns (HIGH)

### component-jsx-three

Use JSX elements for Three.js objects:

```tsx
// Three.js classes become lowercase JSX elements
<mesh>
  <boxGeometry args={[1, 1, 1]} />
  <meshStandardMaterial color="hotpink" />
</mesh>
```

### component-attach

Use attach prop for non-standard properties:

```tsx
<mesh>
  <boxGeometry />
  <meshStandardMaterial attach="material" />
</mesh>

// For arrays
<group>
  <mesh attach="children-0" />
  <mesh attach="children-1" />
</group>
```

### component-primitive

Use primitive for external/imperative objects:

```tsx
const geometry = useMemo(() => new BoxGeometry(1, 1, 1), [])
return <primitive object={geometry} attach="geometry" />
```

### component-extend

Extend custom Three.js classes:

```tsx
import { extend } from '@react-three/fiber'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'

extend({ OrbitControls })

// Now available as JSX
<orbitControls args={[camera, domElement]} />
```

### component-dispose-null

Prevent disposal of shared resources:

```tsx
// Shared geometry used by multiple meshes
<mesh geometry={sharedGeometry} dispose={null} />
```

---

## 4. Canvas & Setup (HIGH)

### canvas-container

Configure dimensions via CSS container:

```tsx
<div style={{ width: '100vw', height: '100vh' }}>
  <Canvas>
    <Scene />
  </Canvas>
</div>
```

### canvas-camera

Set camera via prop:

```tsx
<Canvas camera={{ position: [0, 5, 10], fov: 50 }}>
```

### canvas-shadows

Enable shadows at Canvas level:

```tsx
<Canvas shadows>
  <directionalLight castShadow />
  <mesh receiveShadow castShadow />
</Canvas>
```

### canvas-frameloop

Choose appropriate frameloop mode:

```tsx
// Always render (default)
<Canvas frameloop="always">

// On-demand (call invalidate())
<Canvas frameloop="demand">

// Never (manual control)
<Canvas frameloop="never">
```

### canvas-color-space

Use linear/flat for correct colors:

```tsx
<Canvas flat linear>
  {/* Disables tone mapping and uses linear color space */}
</Canvas>
```

---

## 5. Drei Helpers (MEDIUM-HIGH)

### drei-usegltf

Use useGLTF with preloading:

```tsx
import { useGLTF } from '@react-three/drei'

function Model() {
  const { scene } = useGLTF('/model.glb')
  return <primitive object={scene} />
}

// Preload at module level
useGLTF.preload('/model.glb')
```

### drei-usetexture

Efficient texture loading:

```tsx
import { useTexture } from '@react-three/drei'

function TexturedMesh() {
  const texture = useTexture('/texture.jpg')
  return <meshStandardMaterial map={texture} />
}

useTexture.preload('/texture.jpg')
```

### drei-environment

Realistic lighting with Environment:

```tsx
import { Environment } from '@react-three/drei'

<Environment preset="sunset" />
// or
<Environment files="/hdr/studio.hdr" />
```

### drei-orbitcontrols

Import OrbitControls from Drei:

```tsx
// GOOD - Use Drei's version
import { OrbitControls } from '@react-three/drei'
<OrbitControls />

// BAD - Manual extend
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'
extend({ OrbitControls })
```

### drei-html

DOM overlays with Html:

```tsx
import { Html } from '@react-three/drei'

<mesh>
  <Html center>
    <div className="label">Click me</div>
  </Html>
</mesh>
```

### drei-text

Performant 2D text:

```tsx
import { Text } from '@react-three/drei'

<Text fontSize={0.5} color="white">
  Hello World
</Text>
```

### drei-instances

Optimized many-object rendering:

```tsx
import { Instances, Instance } from '@react-three/drei'

<Instances>
  <boxGeometry />
  <meshStandardMaterial />
  {positions.map((pos, i) => (
    <Instance key={i} position={pos} />
  ))}
</Instances>
```

---

## 6. Loading & Suspense (MEDIUM-HIGH)

### loading-suspense

Wrap async components in Suspense:

```tsx
<Suspense fallback={<Loader />}>
  <Model />
</Suspense>
```

### loading-preload

Preload assets at module level:

```tsx
// Top of file
useGLTF.preload('/model.glb')
useTexture.preload('/texture.jpg')

function Scene() {
  // Assets already cached
}
```

### loading-useprogress

Loading UI with useProgress:

```tsx
import { useProgress, Html } from '@react-three/drei'

function Loader() {
  const { progress } = useProgress()
  return <Html center>{progress.toFixed(0)}%</Html>
}
```

### loading-lazy

Lazy load heavy components:

```tsx
const HeavyScene = lazy(() => import('./HeavyScene'))

<Suspense fallback={<Placeholder />}>
  <HeavyScene />
</Suspense>
```

---

## 7. State Management (MEDIUM)

### state-focused-stores

Create focused stores by concern:

```tsx
// Separate stores for different concerns
const usePlayerStore = create((set) => ({
  health: 100,
  damage: (amount) => set(s => ({ health: s.health - amount }))
}))

const useInventoryStore = create((set) => ({
  items: [],
  addItem: (item) => set(s => ({ items: [...s.items, item] }))
}))
```

### state-no-mutable-objects

Don't store mutable Three.js objects:

```tsx
// BAD - Storing Vector3 directly
const useStore = create(() => ({
  position: new Vector3() // Mutable, causes issues
}))

// GOOD - Store primitives
const useStore = create(() => ({
  position: [0, 0, 0] // Immutable array
}))
```

### state-subscribe-selector

Fine-grained updates with subscribeWithSelector:

```tsx
import { subscribeWithSelector } from 'zustand/middleware'

const useStore = create(
  subscribeWithSelector((set) => ({
    score: 0,
  }))
)

// Subscribe to specific changes
useStore.subscribe(
  state => state.score,
  score => console.log('Score changed:', score)
)
```

---

## 8. Events & Interaction (MEDIUM)

### events-pointer

Pointer events on meshes:

```tsx
<mesh
  onClick={(e) => console.log('clicked', e.point)}
  onPointerOver={(e) => setHovered(true)}
  onPointerOut={(e) => setHovered(false)}
>
```

### events-stoppropagation

Prevent event bubbling:

```tsx
<mesh onClick={(e) => {
  e.stopPropagation()
  handleClick()
}}>
```

### events-cursor

Change cursor on hover:

```tsx
<mesh
  onPointerOver={() => document.body.style.cursor = 'pointer'}
  onPointerOut={() => document.body.style.cursor = 'auto'}
>
```

### events-raycast-filter

Filter raycasting for performance:

```tsx
// Only raycast visible meshes
<mesh raycast={mesh.visible ? undefined : () => null}>
```

---

## 9. Post-processing (MEDIUM)

### postpro-effectcomposer

Use EffectComposer from @react-three/postprocessing:

```tsx
import { EffectComposer, Bloom, Noise } from '@react-three/postprocessing'

<EffectComposer>
  <Bloom intensity={0.5} />
  <Noise opacity={0.02} />
</EffectComposer>
```

### postpro-smaa

Use SMAA for anti-aliasing:

```tsx
import { EffectComposer, SMAA } from '@react-three/postprocessing'

<EffectComposer multisampling={0}> {/* Disable MSAA */}
  <SMAA />
</EffectComposer>
```

### postpro-selective-bloom

Optimized glow with SelectiveBloom:

```tsx
import { Selection, Select, EffectComposer, SelectiveBloom } from '@react-three/postprocessing'

<Selection>
  <EffectComposer>
    <SelectiveBloom />
  </EffectComposer>
  <Select enabled>
    <mesh /> {/* Only this mesh blooms */}
  </Select>
</Selection>
```

---

## 10. Physics / Rapier (LOW-MEDIUM)

### physics-setup

Basic Physics setup:

```tsx
import { Physics, RigidBody } from '@react-three/rapier'

<Physics gravity={[0, -9.81, 0]}>
  <RigidBody>
    <mesh>
      <boxGeometry />
    </mesh>
  </RigidBody>
</Physics>
```

### physics-body-types

Choose appropriate RigidBody types:

```tsx
// Affected by physics
<RigidBody type="dynamic">

// Never moves
<RigidBody type="fixed">

// Controlled programmatically
<RigidBody type="kinematicPosition">
```

### physics-simple-colliders

Use simple colliders for performance:

```tsx
// GOOD - Simple shapes
<RigidBody colliders="cuboid" />
<RigidBody colliders="ball" />

// EXPENSIVE - Avoid for moving objects
<RigidBody colliders="trimesh" />
```

### physics-collision-events

Handle collisions:

```tsx
<RigidBody
  onCollisionEnter={({ other }) => {
    console.log('Hit:', other.rigidBodyObject)
  }}
  onCollisionExit={() => {
    console.log('Left collision')
  }}
>
```

---

## Quick Reference

### NEVER Do

- `setState` inside `useFrame`
- Subscribe to entire Zustand store
- Inline object/array props in JSX
- Index-based keys for dynamic lists
- Heavy computations in animation loop

### ALWAYS Do

- Use refs for continuous mutations
- Use Zustand selectors
- Wrap async in Suspense
- Preload assets at module level
- Use delta time for animations

### Common Patterns

```tsx
// Animation without re-renders
const ref = useRef()
useFrame((_, delta) => {
  ref.current.rotation.y += delta
})

// State access without re-renders
useFrame(() => {
  const { target } = useStore.getState()
})

// Loading with progress
<Suspense fallback={<Loader />}>
  <AsyncComponent />
</Suspense>
```
