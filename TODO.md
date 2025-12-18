Todo list

[x] Draw / Erase instances

[x] Simple grid spatial partitioning

[x] Edit multiple mesh groups simultaneously

[x] Placement based on distance rules

[X] Brush Preview

[X] Brush Size

[X] Add undo / redo

[X] Fix data mismatch between editor and node when modifying data block

[X] instance spawn distance option

[X] Paint Mode

[X] Scale Mode

[X] Color Mode

[X] Base UI

[X] instance base scale option

[X] Layer system (chose which group of items are affected by editing modes)

[X] Update readme

[X] Add mm+ node Icon

[X] Hide when MMPlus3D parent node is hidden

[X] Update transform when MMPlus3D parent node transform update

[X] Fix placement on parent with translation or rotation applied

[X] Probability based placement.

[] Make data block more resilient to changes.

[] Better placement (Poisson disk sampling?).

[X] Align on normal option.

[X] Align on brush direction option.

[X] Random rotate around Y axis option.

[] Grid Size option.

- By default, MMgrid will partition the space into a grid with cells that are 50 in size.

[] Spread in volume / spread on surface option.

[] Custom vertex color / custom data option.

- Currently, the plugin expect all multimesh to use the color option (storing 16 floats per instance by default in the buffer), but we should be able to switch between, transform only, transform + vertex color, and transform + vertex color + custom data.
