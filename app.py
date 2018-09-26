#!/usr/bin/env python
from app import socketio, app

if __name__ == '__main__':
    print('starting app')
    socketio.run(app, debug=True, port=8080, host='0.0.0.0')
