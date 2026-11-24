import unittest

from check_keyboard_course import KEYS
from x11_physical_keys import EVDEV_SCANCODES, physical_x11_keycode


class PhysicalX11KeycodeTests(unittest.TestCase):
    def test_course_keys_have_physical_codes(self):
        self.assertEqual(KEYS - EVDEV_SCANCODES.keys(), set())

    def test_keycode_is_evdev_scancode_plus_x11_offset(self):
        self.assertEqual(physical_x11_keycode('KeyW'), 25)
        self.assertEqual(physical_x11_keycode('KeyJ'), 44)
        self.assertEqual(physical_x11_keycode('Comma'), 59)

    def test_character_labels_are_not_accepted_as_physical_keys(self):
        with self.assertRaises(ValueError):
            physical_x11_keycode('j')


if __name__ == '__main__':
    unittest.main()
