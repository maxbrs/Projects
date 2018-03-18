#! /usr/bin/env python
# -*- coding:utf-8 -*-

from flask import Flask, request
from PIL import Image
from io import StringIO
from flask import make_response
app = Flask(__name__)

@app.route('/')
def racine():
    return "Le chemin de 'racine' est : " + request.path

@app.route('/la/')
def ici():
    return '''Le chemin de 'ici' est : ''' + request.path

@app.route('/coucou/')
def dire_coucou():
    return 'Coucou !'

# @app.route('/contact/', methods=['GET', 'POST'])
# def contact():
#     if request.method == 'GET':
#         print('afficher le formulaire')
#     else:
#         print('traiter les données reçues')
#         print('''Merci de m'avoir laissé un message !''')

@app.route('/discussion/')
@app.route('/discussion/page/<int:num_page>')
def mon_chat(num_page=1):
    premier_msg = 1 + 50 * (num_page - 1)
    dernier_msg = premier_msg + 50
    return 'affichage des messages {} à {}'.format(premier_msg, dernier_msg)

@app.route('/afficher/')
@app.route('/afficher/<prenom>.<nom>')
def afficher(nom=None, prenom=None):
    if nom is None or prenom is None:
        return "Entrez votre nom et votre prénom comme il le faut dans l'url"
    return "Vous vous appelez {} {} !".format(prenom, nom)

@app.route('/image/')
def genere_image():
    mon_image = StringIO()
    Image.new("RGB", (300,300), "#92C41D").save(mon_image, 'BMP', mode="wb")
    reponse = make_response(mon_image.getvalue())
    reponse.mimetype = "image/bmp"  # à la place de "text/html"
    return reponse


if __name__ == '__main__':
    app.run(debug=True)
