# -*- coding: utf-8 -*-


from flask import Flask, jsonify, request
from flask_mysqldb import MySQL
from datetime import datetime
import simplejson as json

app = Flask(__name__)
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'admin'
app.config['MYSQL_PORT'] = 5005
app.config['MYSQL_DB'] = 'BikeStations'
mysql = MySQL(app)

@app.route('/', methods = ['GET'])
@app.route('/tables/', methods = ['GET'])
def index():
	cur = mysql.connection.cursor()
	cur.execute('''SHOW TABLES''')
	val = cur.fetchall()
	results = []
	for i in val:
		results.append(i)
	return jsonify({'tables': results})

@app.route('/getall_bike/', methods = ['GET'])
def getall_bike():
	cur = mysql.connection.cursor()
	cur.execute('''SELECT * FROM BIKE''')
	val = cur.fetchall()
	results = []
	for i in val:
		results.append({'bik_ID': i[0],
						'bik_sta_ID': i[1],
						'bik_timestamp': i[2],
						'bik_status': i[3],
						'bik_stands': i[4],
						'bik_available_stands': i[5],
						'bik_available': i[6]})
	return jsonify({'nb_records': len(results),
					'bike': results})

@app.route('/getall_city/', methods = ['GET'])
def getall_city():
	cur = mysql.connection.cursor()
	cur.execute('''SELECT count(distinct sta_city) FROM STATION''')
	nb_cities = cur.fetchone()
	cur.execute('''SELECT distinct sta_city FROM STATION''')
	val = cur.fetchall()
	return jsonify({'nb_cities': nb_cities,
					'cities': val})

@app.route('/getall_station/', methods = ['GET'])
def getall_station():
	cur = mysql.connection.cursor()
	cur.execute('''SELECT * FROM STATION''')
	val = cur.fetchall()
	results = []
	for i in val:
		results.append({'sta_ID': i[0],
						'sta_number': i[1],
						'sta_lat': i[2],
						'sta_lon': i[3],
						'sta_name': i[4],
						'sta_city': i[5],
						'sta_address': i[6],
						'sta_payment': i[7],
						'sta_bonus': i[8],})
	return jsonify({'nb_records': len(results),
					'station': results})

@app.route('/post_bikedata/', methods = ['POST'])
def add_bikedata():
	data = request.get_json()#force = True
	data = json.loads(data)
	#print(type(data))
	#print(data[0])
	for each in data:
		name = each['name'].replace('\'', ' ')
		lat = each['position']['lat']
		lon = each['position']['lng']
		address = each['address'].replace('\'', ' ')
		available_bike_stands = each['available_bike_stands']
		available_bikes = each['available_bikes']
		banking = each['banking']
		bonus = each['bonus']
		bike_stands = each['bike_stands']
		city = each['contract_name'].replace('\'', ' ')
		number = each['number']
		status = each['status']
		time = datetime.fromtimestamp(int(str(each['last_update'])[:-3])).strftime('%Y-%m-%d %H:%M:%S')
		try :
			call_bikestation(name, lat, lon, address, available_bike_stands, available_bikes, banking, bonus, bike_stands, city, number, status, time)
			print('Insert done')
		except:
			print('Unable to insert data')
			print("CALL ADD_BIKE_STATION('"+str(name)+"'," + str(lat)+","+str(lon)+",'"+str(address)+"',"+str(available_bike_stands)+","+str(available_bikes)+","+str(banking)+","+str(bonus)+","+str(bike_stands)+",'"+str(city)+"',"+str(number)+",'"+str(status)+"','"+str(time)+"');")
	query = "COMMIT ;"
	cur = mysql.connection.cursor()
	cur.execute(query)
	return 'DONE !'

def call_bikestation(name, lat, lon, address, available_bike_stands, available_bikes, banking, bonus, bike_stands, city, number, status, time):
	query = "CALL ADD_BIKE_STATION('"+str(name)+"'," + str(lat)+","+str(lon)+",'"+str(address)+"',"+str(available_bike_stands)+","+str(available_bikes)+","+str(banking)+","+str(bonus)+","+str(bike_stands)+",'"+str(city)+"',"+str(number)+",'"+str(status)+"','"+str(time)+"');"
	cur = mysql.connection.cursor()
	cur.execute(query)

if __name__ == '__main__':
	app.run(debug=True)
