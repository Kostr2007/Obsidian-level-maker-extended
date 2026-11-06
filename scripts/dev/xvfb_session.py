#!/usr/bin/env python3
"""Own an Xvfb server and wait for its readiness notification before using it."""
import os
from pathlib import Path
import re
import select
import subprocess
import time


def ensure_running(process, logfile):
    code = process.poll()
    if code is not None:
        path = Path(logfile)
        details = path.read_text(errors='replace') if path.exists() else '(no log)'
        raise RuntimeError(f'Process exited with status {code}; {path}:\n{details}')


def wait_for(predicate, message, timeout=30, processes=()):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for process, logfile in processes:
            ensure_running(process, logfile)
        try:
            result = predicate()
            if result:
                return result
        except (subprocess.CalledProcessError, IndexError):
            pass
        time.sleep(.15)
    raise RuntimeError(message)


class XvfbSession:
    """An isolated display; an explicit occupied display is never borrowed.

    -displayfd is written only once Xvfb is ready. -noreset keeps the display
    available between the short-lived xdotool clients and the Qt application.
    """
    def __init__(self, logfile, screen, env=None, requested_display=None):
        self.logfile = Path(logfile)
        self.screen = screen
        self.env = os.environ.copy() if env is None else env.copy()
        self.requested_display = requested_display
        self.process = None
        self.name = None

    def __enter__(self):
        if self.requested_display and not re.fullmatch(r':\d+', self.requested_display):
            raise ValueError('An Xvfb display override must have the form :NUMBER')
        reader, writer = os.pipe()
        try:
            args = ['Xvfb']
            if self.requested_display:
                args.append(self.requested_display)
            args += ['-displayfd', str(writer), '-screen', '0', self.screen,
                     '-nolisten', 'tcp', '-noreset']
            with self.logfile.open('w') as log:
                self.process = subprocess.Popen(args, env=self.env, pass_fds=(writer,),
                                                stdout=log, stderr=subprocess.STDOUT)
            os.close(writer)
            writer = None
            deadline = time.monotonic() + 30
            ready = b''
            while b'\n' not in ready:
                ensure_running(self.process, self.logfile)
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    raise RuntimeError(f'Xvfb did not become ready; see {self.logfile}')
                if select.select([reader], [], [], min(.1, remaining))[0]:
                    chunk = os.read(reader, 80)
                    if not chunk:
                        raise RuntimeError(f'Xvfb closed its readiness pipe; {self.logfile}:\n'
                                           + self.logfile.read_text(errors='replace'))
                    ready += chunk
            number = ready.strip().decode('ascii')
            if not number.isdigit():
                raise RuntimeError(f'Invalid Xvfb display notification: {number!r}')
            ensure_running(self.process, self.logfile)
            self.name = ':' + number
            self.env['DISPLAY'] = self.name
            return self
        except BaseException:
            self.stop()
            raise
        finally:
            os.close(reader)
            if writer is not None:
                os.close(writer)

    def stop(self):
        if self.process is not None and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=5)

    def __exit__(self, *_):
        self.stop()
