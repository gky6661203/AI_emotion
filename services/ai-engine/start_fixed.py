import sys
import typing

original_evaluate = typing.ForwardRef._evaluate

def patched_evaluate(self, globalns, localns, *args, **kwargs):
    return original_evaluate(self, globalns, localns)

typing.ForwardRef._evaluate = patched_evaluate

import uvicorn
from main import app

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8090)