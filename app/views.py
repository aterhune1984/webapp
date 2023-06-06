from app import app, socketio, Response
from flask import render_template
from prometheus_client import generate_latest
from prometheus_client import Counter
http_requests_total = Counter('pageloads_total', 'Total page loads')

@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
def index():
    http_requests_total.inc()
    return render_template('index.html', async_mode=socketio.async_mode)


@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')
