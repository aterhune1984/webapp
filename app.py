#!/usr/bin/env python
from app import socketio, app
from prometheus_flask_exporter import PrometheusMetrics

metrics = PrometheusMetrics(app)

if __name__ == '__main__':
    print('starting app')
    metrics.start_http_server(port=8080)
    socketio.run(app, debug=True, host='0.0.0.0')
