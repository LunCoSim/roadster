"""OS XTest input restricted to the PID of an owned X11 test window.

This exercises X11 -> winit -> native intents. It is synthetic OS input, not
physical hardware or evidence that a human completed the course. No global
keyboard layout/repeat settings are changed. Requires python-xlib and XTEST.
"""
import time
from Xlib import X, XK, display
from Xlib.ext import xtest
from Xlib.protocol import event

SYMBOLS = {'Space':'space','Tab':'Tab','ShiftLeft':'Shift_L',
           'ControlLeft':'Control_L','ControlRight':'Control_R'}

class X11WindowInput:
    def __init__(self, pid):
        self.display=display.Display()
        if not self.display.has_extension('XTEST'):
            raise RuntimeError('XTEST is unavailable on this DISPLAY')
        self.root=self.display.screen().root
        self.pid_atom=self.display.intern_atom('_NET_WM_PID')
        self.held=set();self.events=[];self.previous_focus=self.display.get_input_focus().focus
        self.window=None
        deadline=time.monotonic()+30
        while time.monotonic()<deadline:
            candidates=[]
            def visit(window,depth=0):
                try:
                    prop=window.get_full_property(self.pid_atom,X.AnyPropertyType)
                    if prop is not None and len(prop.value) and int(prop.value[0])==pid:
                        if window.get_attributes().map_state==X.IsViewable:candidates.append(window)
                    if depth<4:
                        for child in window.query_tree().children:visit(child,depth+1)
                except Exception:pass
            visit(self.root)
            if candidates:
                self.window=max(candidates,key=lambda w:w.get_geometry().width*w.get_geometry().height)
                break
            time.sleep(.05)
        if self.window is None:raise RuntimeError(f'No mapped X11 window belongs to owned PID {pid}')
        if self.root.query_pointer().mask & (X.ShiftMask|X.ControlMask|X.Mod1Mask):
            raise RuntimeError('Release physical Shift/Ctrl/Alt before the owned OS input test')
        self.pid=pid

    def activate(self):
        # Ask the window manager to activate the owned client. Directly forcing
        # X input focus can be immediately reverted by the Wayland compositor.
        atom=self.display.intern_atom('_NET_ACTIVE_WINDOW')
        request=event.ClientMessage(window=self.window,client_type=atom,
            data=(32,[2,X.CurrentTime,0,0,0]))
        self.root.send_event(request,event_mask=X.SubstructureRedirectMask|X.SubstructureNotifyMask)
        self.display.flush()
        deadline=time.monotonic()+3
        stable_since=None
        while time.monotonic()<deadline:
            try:
                self.ensure_focus()
                if stable_since is None:stable_since=time.monotonic()
                if time.monotonic()-stable_since>=.3:return
            except RuntimeError:stable_since=None
            time.sleep(.05)
        raise RuntimeError('Owned OS test window did not retain foreground focus for 300 ms; no input sent')

    def ensure_focus(self):
        window=self.display.get_input_focus().focus
        for _ in range(8):
            if getattr(window,'id',None)==self.window.id:return
            if not hasattr(window,'query_tree'):break
            try:window=window.query_tree().parent
            except Exception:break
        focus=self.display.get_input_focus().focus
        actual=getattr(focus,'id',focus)
        raise RuntimeError(f'Owned OS test window lost focus (owned={self.window.id}, actual={actual}); refusing to send further input')

    def key(self, key, state):
        if state=='Pressed':self.ensure_focus()
        symbol=SYMBOLS.get(key,key[3:].lower() if key.startswith('Key') else key)
        code=self.display.keysym_to_keycode(XK.string_to_keysym(symbol))
        if not code:raise RuntimeError(f'X11 has no keycode for {symbol}')
        xtest.fake_input(self.display,X.KeyPress if state=='Pressed' else X.KeyRelease,code)
        self.display.sync()
        self.events.append(dict(kind='key',key=key,state=state))
        if state=='Pressed':self.held.add(key)
        else:self.held.discard(key)

    def pointer(self,state,x,y):
        self.ensure_focus()
        pos=self.root.translate_coords(self.window,0,0)
        xtest.fake_input(self.display,X.MotionNotify,x=pos.x+int(x),y=pos.y+int(y))
        xtest.fake_input(self.display,X.ButtonPress if state=='Pressed' else X.ButtonRelease,1)
        self.display.sync()
        self.events.append(dict(kind='pointer',state=state,x=x,y=y))

    def held_state(self):
        bits=self.display.query_keymap()
        values={}
        for key in self.held:
            symbol=SYMBOLS.get(key,key[3:].lower() if key.startswith('Key') else key)
            code=self.display.keysym_to_keycode(XK.string_to_keysym(symbol))
            values[key]=bool(bits[code//8] & (1 << (code%8)))
        return dict(server_keys=values,focus_window=getattr(self.display.get_input_focus().focus,'id',None),
            owned_window=self.window.id)

    def release(self):
        for key in sorted(self.held,key=lambda k:k.startswith('Control')):
            self.key(key,'Released')

    def close(self):
        self.release()
        try:
            if hasattr(self.previous_focus,'set_input_focus'):
                self.previous_focus.set_input_focus(X.RevertToParent,X.CurrentTime)
                self.display.sync()
        except Exception:pass
        self.display.close()
