"""Map the Linux Bevy physical key names used by tests to X11 keycodes."""

# Linux evdev physical scancodes. X11/XWayland keycodes use the evdev code + 8,
# matching Winit's Linux physical-key translation. This is a physical-position
# table, not a map of keyboard layouts or produced characters.
EVDEV_SCANCODES = {
    'Tab': 15,
    'KeyQ': 16, 'KeyW': 17, 'KeyE': 18, 'KeyR': 19,
    'KeyT': 20, 'KeyY': 21, 'KeyU': 22, 'KeyI': 23,
    'KeyO': 24, 'KeyP': 25,
    'ControlLeft': 29,
    'KeyA': 30, 'KeyS': 31, 'KeyD': 32, 'KeyF': 33,
    'KeyG': 34, 'KeyH': 35, 'KeyJ': 36, 'KeyK': 37,
    'KeyL': 38,
    'ShiftLeft': 42,
    'KeyZ': 44, 'KeyX': 45, 'KeyC': 46, 'KeyV': 47,
    'KeyB': 48, 'KeyN': 49, 'KeyM': 50,
    'Comma': 51, 'Period': 52,
    'ShiftRight': 54, 'Space': 57,
    'ControlRight': 97,
}


def physical_x11_keycode(key):
    """Return the X11 keycode for a Bevy physical KeyCode name."""
    try:
        return EVDEV_SCANCODES[key] + 8
    except KeyError as exc:
        raise ValueError(f'No Linux physical scancode is defined for {key!r}') from exc
