from app import app, socketio, Response
from flask import render_template
from prometheus_client import generate_latest

@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
def index():
    return render_template('index.html', async_mode=socketio.async_mode)


@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype='text/plain')
