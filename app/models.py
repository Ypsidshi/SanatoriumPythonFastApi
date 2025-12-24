from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    Date,
    ForeignKey,
    Integer,
    String,
    Table,
)
from sqlalchemy.orm import declarative_base, relationship


Base = declarative_base()

provision_of_services = Table(
    "provision_of_services",
    Base.metadata,
    Column("service", ForeignKey("service.id_service", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
    Column("pansionat", ForeignKey("pansionat.id_pansionat", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
)

using_service = Table(
    "using_service",
    Base.metadata,
    Column("service", ForeignKey("service.id_service", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
    Column("resident", ForeignKey("resident.id_resident", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
)

vladenie = Table(
    "vladenie",
    Base.metadata,
    Column("administrator", ForeignKey("administrator.id_administrator", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
    Column("pansionat", ForeignKey("pansionat.id_pansionat", ondelete="CASCADE", onupdate="CASCADE"), primary_key=True),
)


class Manager(Base):
    __tablename__ = "manager"

    id_manager = Column(Integer, primary_key=True, autoincrement=True)
    surname = Column(String(30), nullable=False)
    name = Column(String(30), nullable=False)
    otchestvo = Column(String(30), nullable=False)
    adress = Column(String(255), nullable=False)
    mail = Column(String(255), nullable=False, unique=True)
    telephone = Column(BigInteger, nullable=False)

    residents = relationship("Resident", back_populates="manager")
    contracts = relationship("Contract", back_populates="manager")


class Administrator(Base):
    __tablename__ = "administrator"

    id_administrator = Column(Integer, primary_key=True, autoincrement=True)
    surname = Column(String(30), nullable=False)
    name = Column(String(30), nullable=False)
    otchestvo = Column(String(30), nullable=False)
    adress = Column(String(255), nullable=False)
    mail = Column(String(255), nullable=False, unique=True)
    telephone = Column(BigInteger, nullable=False)

    pansionat_links = relationship("Pansionat", secondary=vladenie, back_populates="administrators")


class HealthProfile(Base):
    __tablename__ = "health_profile"

    id_health_profile = Column(Integer, primary_key=True, autoincrement=True)
    profile = Column(String(255), nullable=False)

    pansionats = relationship("Pansionat", back_populates="health_profile")


class StatusRoom(Base):
    __tablename__ = "status_room"

    id_status_room = Column(Integer, primary_key=True, autoincrement=True)
    status = Column(Boolean, nullable=False)

    rooms = relationship("Room", back_populates="status_room")


class StatusOfContract(Base):
    __tablename__ = "status_of_contract"

    id_status_of_contract = Column(Integer, primary_key=True, autoincrement=True)
    status = Column(Boolean, nullable=False)

    contracts = relationship("Contract", back_populates="status_of_contract")


class RoomType(Base):
    __tablename__ = "room_type"

    id_type = Column(Integer, primary_key=True, autoincrement=True)
    type = Column(String(255), nullable=False)

    rooms = relationship("Room", back_populates="room_type")


class Pansionat(Base):
    __tablename__ = "pansionat"

    id_pansionat = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False, unique=True)
    photo = Column(String(255), nullable=True)
    buiding_year = Column(Integer, nullable=False)
    administrator_id = Column("administrator", Integer, ForeignKey("administrator.id_administrator"), nullable=False)
    health_profile_id = Column("health_profile", Integer, ForeignKey("health_profile.id_health_profile"), nullable=False)

    health_profile = relationship("HealthProfile", back_populates="pansionats")
    rooms = relationship("Room", back_populates="pansionat")
    services = relationship("Service", secondary=provision_of_services, back_populates="pansionats")
    administrators = relationship("Administrator", secondary=vladenie, back_populates="pansionat_links")


class Service(Base):
    __tablename__ = "service"

    id_service = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(30), nullable=False)
    price = Column(Integer, nullable=False)
    time = Column(String(255), nullable=False)

    pansionats = relationship("Pansionat", secondary=provision_of_services, back_populates="services")
    residents = relationship("Resident", secondary=using_service, back_populates="services")


class Room(Base):
    __tablename__ = "room"

    id_room = Column(Integer, primary_key=True, autoincrement=True)
    price = Column(Integer, nullable=False)
    pansionat_id = Column("pansionat", Integer, ForeignKey("pansionat.id_pansionat"), nullable=False)
    type_id = Column("type", Integer, ForeignKey("room_type.id_type"), nullable=False)
    status_room_id = Column("status_room", Integer, ForeignKey("status_room.id_status_room"), nullable=False)

    pansionat = relationship("Pansionat", back_populates="rooms")
    room_type = relationship("RoomType", back_populates="rooms")
    status_room = relationship("StatusRoom", back_populates="rooms")
    contracts = relationship("Contract", back_populates="room")


class Resident(Base):
    __tablename__ = "resident"

    id_resident = Column(Integer, primary_key=True, autoincrement=True)
    surname = Column(String(30), nullable=False)
    name = Column(String(30), nullable=False)
    otchestvo = Column(String(30), nullable=False)
    mail = Column(String(255), nullable=False, unique=True)
    telephone = Column(BigInteger, nullable=False)
    passport = Column(BigInteger, nullable=False, unique=True)
    manager_id = Column("manager", Integer, ForeignKey("manager.id_manager"), nullable=False)
    pansionat_id = Column("pansionat", Integer, ForeignKey("pansionat.id_pansionat"), nullable=True)

    manager = relationship("Manager", back_populates="residents")
    contracts = relationship("Contract", back_populates="resident")
    services = relationship("Service", secondary=using_service, back_populates="residents")


class Contract(Base):
    __tablename__ = "contract"

    id_contract = Column(Integer, primary_key=True, autoincrement=True)
    start_date = Column(Date, nullable=False)
    final_date = Column(Date, nullable=False)
    summa = Column(Integer, nullable=False)
    manager_id = Column("manager", Integer, ForeignKey("manager.id_manager"), nullable=False)
    room_id = Column("room", Integer, ForeignKey("room.id_room"), nullable=False)
    resident_id = Column("resident", Integer, ForeignKey("resident.id_resident"), nullable=False)
    status_of_contract_id = Column(
        "status_of_contract",
        Integer,
        ForeignKey("status_of_contract.id_status_of_contract"),
        nullable=False,
    )

    manager = relationship("Manager", back_populates="contracts")
    room = relationship("Room", back_populates="contracts")
    resident = relationship("Resident", back_populates="contracts")
    status_of_contract = relationship("StatusOfContract", back_populates="contracts")
