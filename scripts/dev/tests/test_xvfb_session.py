"""Integration checks for ownership/readiness across real X11 client sessions."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from xvfb_session import XvfbSession, wait_for


class ChildFailureTests(unittest.TestCase):
    def test_failed_child_reports_log_without_window_timeout(self):
        with tempfile.TemporaryDirectory() as temporary:
            log = Path(temporary) / 'launch.log'
            with log.open('w') as output:
                child = subprocess.Popen([sys.executable, '-c', 'print("display unavailable"); raise SystemExit(7)'], stdout=output)
                child.wait(timeout=5)
            start = time.monotonic()
            with self.assertRaisesRegex(RuntimeError, 'display unavailable'):
                wait_for(lambda: False, 'window timeout', timeout=30, processes=((child, log),))
            self.assertLess(time.monotonic() - start, 1)


@unittest.skipUnless(shutil.which('Xvfb') and shutil.which('xdotool'), 'Xvfb and xdotool are required')
class XvfbIntegrationTests(unittest.TestCase):
    def test_isolated_displays_survive_disconnected_clients(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with XvfbSession(directory / 'first.log', '640x480x24') as first:
                with XvfbSession(directory / 'second.log', '800x600x24') as second:
                    self.assertNotEqual(first.name, second.name)
                    for _ in range(12):
                        for session, expected in ((first, '640 480'), (second, '800 600')):
                            geometry = subprocess.check_output(['xdotool', 'getdisplaygeometry'], env=session.env, text=True).strip()
                            self.assertEqual(geometry, expected)
                            self.assertIsNone(session.process.poll())
                self.assertIsNotNone(second.process.poll())
            self.assertIsNotNone(first.process.poll())

    def test_occupied_override_does_not_borrow_existing_server(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            with XvfbSession(directory / 'first.log', '640x480x24') as first:
                with self.assertRaises(RuntimeError):
                    with XvfbSession(directory / 'occupied.log', '800x600x24', requested_display=first.name):
                        self.fail('Borrowed or replaced the occupied display')
                self.assertIsNone(first.process.poll())
                geometry = subprocess.check_output(['xdotool', 'getdisplaygeometry'], env=first.env, text=True).strip()
                self.assertEqual(geometry, '640 480')


if __name__ == '__main__':
    unittest.main()
