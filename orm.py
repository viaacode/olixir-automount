from sqlalchemy import Column, DateTime, String, create_engine, Integer
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import scoped_session, sessionmaker

Base = declarative_base()


class Bay(Base):
    __tablename__ = 'bays'
    disk_bay = Column(Integer(), primary_key=True)
    OR_ID = Column(String(10), unique=True)
    status = Column(String(20))
    created = Column(DateTime())
    updated = Column(DateTime())
    cp = Column(String(30))
    disk_serial = Column(String(10), unique=True)

    def update(self,  disk_bay=None, OR_ID=None, status=None, created=None,
               updated=None, cp=None, disk_serial=None):
        if OR_ID is not None:
            self.OR_ID = OR_ID
        if disk_serial is not None:
            self.disk_serial = disk_serial
        if cp is not None:
            self.cp = cp
        if status is not None:
            self.status = status
        if created is not None:
            self.created = created
        if updated is not None:
            self.updated = updated            

    def dump(self):
        return dict([(k, v) for k, v in vars(self).items() if not k.startswith('_')])


def init_db(uri):
    engine = create_engine(uri, convert_unicode=True, echo=True)
    db_session = scoped_session(sessionmaker(autocommit=False,
                                             autoflush=False, bind=engine))
    Base.query = db_session.query_property()
    Base.metadata.create_all(bind=engine)
    return db_session
