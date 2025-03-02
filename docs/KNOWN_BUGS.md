# Known Bugs
- First point renders when erasing -- When starting erasing, the canvas renders a single stylus point before continuing. When you start drawing again the original point goes 
- Pull tab doesn't quite slide correctly. When it's right at the edge of view it snaps into place kind of jarringly. Thinking more about this, this should just be a button that always lives in the corner. It's easy to toggle, the touch target stays in the same place for the user. And when I make this better support right handers, it won't compete with the android "swipe from left to go back" gesture.
