### Todo list

- [x] Draw / Erase instances

- [x] Simple grid spatial partitioning

- [x] Edit multiple mesh groups simultaneously

- [x] Placement based on distance rules

- [x] Brush Preview

- [x] Brush Size

- [x] Add undo / redo

- [x] Fix data mismatch between editor and node when modifying data block

- [x] instance spawn distance option

- [x] Paint Mode

- [x] Scale Mode

- [x] Color Mode

- [x] Base UI

- [x] instance base scale option

- [x] Layer system (chose which group of items are affected by editing modes)

- [x] Update readme

- [x] Add mm+ node Icon

- [x] Hide when MMPlus3D parent node is hidden

- [x] Update transform when MMPlus3D parent node transform update

- [x] Fix placement on parent with translation or rotation applied

- [x] Probability based placement.

- [x] Align on normal option.

- [x] Align on brush direction option.

- [x] Random rotate around Y axis option.

- [x] Collision mask option for instance placement

- [x] Grid Size option.

By default, MMgrid will partition the space into a grid with cells that are 50 in size.

- [ ] Make data block more resilient to changes.

- [ ] Better placement (Poisson disk sampling?).

- [ ] Spread in volume / spread on surface option.

- [ ] Custom vertex color / custom data option.

Currently, the plugin expect all multimesh to use the color option (storing 16 floats per instance by default in the buffer), but we should be able to switch between, transform only, transform + vertex color, and transform + vertex color + custom data.
