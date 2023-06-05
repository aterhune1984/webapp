from app import app, socketio, metrics
from flask import render_template


@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
@metrics.counter('hello_world')
def index():
    return render_template('index.html', async_mode=socketio.async_mode)

