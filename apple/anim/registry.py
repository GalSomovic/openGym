"""Registry of animated exercises (see exercises.py and the ex_*.py family modules)."""
EXERCISES = {}


def exercise(id, name, period, active=(), props=("floor",), view="side", extra=None):
    def wrap(fn):
        EXERCISES[id] = dict(id=id, name=name, period=period, active=set(active), props=list(props), view=view, fn=fn, extra=extra)
        return fn
    return wrap
