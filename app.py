#!/usr/bin/env python3
import datetime
import logging
from flask_cors import CORS
import connexion
from connexion import NoContent
from flask import Flask, request, render_template, session, redirect
import pandas as pd
import sqlite3
import orm

db_session = None


def get_Bays(limit, status=None):
    q = db_session.query(orm.Bay)
    if status:
        q = q.filter(orm.Bay.status == status)
    return [p.dump() for p in q][:limit]


def get_Bay(bay_id):
    bay = db_session.query(orm.Bay).filter(orm.Bay.disk_bay == bay_id).one_or_none()
    return bay.dump() if bay is not None else ('Not found', 404)


def put_Bay(bay_id, bay):
    p = db_session.query(orm.Bay).filter(orm.Bay.disk_bay == bay_id).one_or_none()
    bay['disk_bay'] = bay_id
    if p is not None:
        logging.info('Updating bay %s..', bay_id)
        p.update(**bay)
    else:
        logging.info('Creating bay %s..', bay_id)
        bay['created'] = datetime.datetime.utcnow()
        db_session.add(orm.Bay(**bay))
    db_session.commit()
    return NoContent, (200 if p is not None else 201)


def delete_Bay(bay_id):
    bay = db_session.query(orm.Bay).filter(orm.Bay.disk_bay == bay_id).one_or_none()
    if bay is not None:
        logging.info('Deleting bay %s..', bay_id)
        db_session.query(orm.Bay).filter(orm.Bay.disk_bay == bay_id).delete()
        db_session.commit()
        return NoContent, 204
    else:
        return NoContent, 404


logging.basicConfig(level=logging.INFO)
db_session = orm.init_db('sqlite:////tmp/db.sqlite') 
APP = connexion.FlaskApp(__name__)
APP.add_api('openapi.yaml')
application = APP.app

@APP.route('/log')
def html_table():

    conn = sqlite3.connect("/tmp/db.sqlite")
    df = pd.read_sql_query("select * from bays limit 8;", conn)
    logging.info(df)
    return render_template('simple.html',  tables=[df.to_html(classes='data')], titles=df.columns.values)




@application.teardown_appcontext
def shutdown_session(exception=None):
    db_session.remove()

#APP = connexion.FlaskApp('api')
#APP.add_api('openapi.yaml', arguments={'title': 'olixir API'})


if __name__ == '__main__':
    CORS(APP.app)

    APP = connexion.FlaskApp(__name__,
                             port=9090)
    APP.add_api('openapi.yaml',
                arguments={'title': 'Transfer API'})
    APP.run()

#if __name__ == '__main__':
#    CORS(app.app)
#    app.run(port=8081, use_reloader=False, threaded=False)
