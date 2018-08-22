from flask import Flask
from flask import render_template
from flask import send_file, current_app as app

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/about/')
def other():
    return render_template('./about.html')

@app.route('/resume/')
def resume():
	try:
		return send_file('./static/files/resume.pdf', attachment_filename='resume.pdf')
	except Exception as e:
		return str(e)


@app.errorhandler(404)
def page_not_found(error):
    return render_template('page_not_found.html'), 404


if __name__ == '__main__':
	app.run(debug=True)
