from app import app, socketio
from flask import render_template


@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
def index():
    return render_template('index.html', async_mode=socketio.async_mode)
