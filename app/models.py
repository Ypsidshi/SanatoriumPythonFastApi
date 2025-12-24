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
    "provision",
    Base.metadata,
    Column(
        "YclygaID_yclygi",
        ForeignKey("service.ID_service", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
    Column(
        "PansionatID_pansionata",
        ForeignKey("pansionat.ID_pansionat", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
)

using_service = Table(
    "using",
    Base.metadata,
    Column(
        "VillagerID_villager",
        ForeignKey("resident.ID_resident", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
    Column(
        "YclugaID_yclygi",
        ForeignKey("service.ID_service", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
)

ownership = Table(
    "vladenie",
    Base.metadata,
    Column(
        "AdministratorID_Administrator",
        ForeignKey("administrator.ID_administrator", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
    Column(
        "PansionatID_Pansionat",
        ForeignKey("pansionat.ID_pansionat", ondelete="CASCADE", onupdate="CASCADE"),
        primary_key=True,
    ),
)


class Manager(Base):
    __tablename__ = "manager"

    id_manager = Column("ID_manager", Integer, primary_key=True, autoincrement=True)
    surname = Column("Surname", String(30), nullable=False)
    name = Column("Name", String(30), nullable=False)
    otchestvo = Column("Otchectvo", String(30), nullable=False)
    mail = Column("Mail", String(255), nullable=False)
    telephone = Column("Telephone", BigInteger, nullable=False)

    contracts = relationship("Contract", back_populates="manager")


class Administrator(Base):
    __tablename__ = "administrator"

    id_administrator = Column("ID_administrator", Integer, primary_key=True, autoincrement=True)
    surname = Column("Surname", String(30), nullable=False)
    name = Column("Name", String(30), nullable=False)
    otchestvo = Column("Otchectvo", String(30), nullable=False)
    adress = Column("Adress", String(255), nullable=False)
    mail = Column("Mail", String(255), nullable=False)
    telephone = Column("Telephone", BigInteger, nullable=False)

    pansionats = relationship("Pansionat", secondary=ownership, back_populates="administrators")


class HealthProfile(Base):
    __tablename__ = "health_profile"

    id_health_profile = Column("ID_health_profile", Integer, primary_key=True, autoincrement=True)
    profile = Column("Profile", String(255), nullable=False)

    pansionats = relationship("Pansionat", back_populates="health_profile")


class StatusRoom(Base):
    __tablename__ = "status_room"

    id_status_room = Column("ID_status_room", Integer, primary_key=True, autoincrement=True)
    status = Column("Status", Boolean, nullable=False)

    rooms = relationship("Room", back_populates="status_room")


class StatusOfContract(Base):
    __tablename__ = "status_of_contract"

    id_status_of_contract = Column("ID_status_of_contract", Integer, primary_key=True, autoincrement=True)
    status = Column("Status", Boolean, nullable=False)

    contracts = relationship("Contract", back_populates="status_dogovor")


class RoomType(Base):
    __tablename__ = "type"

    id_type = Column("ID_type", Integer, primary_key=True, autoincrement=True)
    type_name = Column("Type", String(255), nullable=False)

    rooms = relationship("Room", back_populates="room_type")


class Pansionat(Base):
    __tablename__ = "pansionat"

    id_pansionat = Column("ID_pansionat", Integer, primary_key=True, autoincrement=True)
    name = Column("Name", String(255), nullable=False)
    photo = Column("Photo", String(255), nullable=True)
    building_year = Column("Building_year", Date, nullable=False)
    health_profile_id = Column(
        "Health_profileD_health_profile",
        Integer,
        ForeignKey("health_profile.ID_health_profile"),
        nullable=False,
    )

    health_profile = relationship("HealthProfile", back_populates="pansionats")
    administrators = relationship("Administrator", secondary=ownership, back_populates="pansionats")
    rooms = relationship("Room", back_populates="pansionat")
    services = relationship("Service", secondary=provision_of_services, back_populates="pansionats")


class Service(Base):
    __tablename__ = "service"

    id_service = Column("ID_service", Integer, primary_key=True, autoincrement=True)
    name = Column("Name", String(30), nullable=False)
    price = Column("Price", Integer, nullable=False)
    time = Column("Time", String(30), nullable=False)

    pansionats = relationship("Pansionat", secondary=provision_of_services, back_populates="services")
    residents = relationship("Resident", secondary=using_service, back_populates="services")


class Room(Base):
    __tablename__ = "room"

    id_room = Column("ID_room", Integer, primary_key=True, autoincrement=True)
    price = Column("Price", Integer, nullable=False)
    pansionat_id = Column("PansionatID_pansionat", Integer, ForeignKey("pansionat.ID_pansionat"), nullable=False)
    status_room_id = Column("StatusID_status_room", Integer, ForeignKey("status_room.ID_status_room"), nullable=False)
    type_id = Column("TypeID_Type", Integer, ForeignKey("type.ID_type"), nullable=False)

    pansionat = relationship("Pansionat", back_populates="rooms")
    room_type = relationship("RoomType", back_populates="rooms")
    status_room = relationship("StatusRoom", back_populates="rooms")
    contracts = relationship("Contract", back_populates="room")


class Resident(Base):
    __tablename__ = "resident"

    id_resident = Column("ID_resident", Integer, primary_key=True, autoincrement=True)
    surname = Column("Surname", String(30), nullable=False)
    name = Column("Name", String(30), nullable=False)
    otchestvo = Column("Otchectvo", String(30), nullable=False)
    mail = Column("Mail", String(255), nullable=False)
    telephone = Column("Telephone", BigInteger, nullable=False)
    passport = Column("Passport", BigInteger, nullable=False)

    contracts = relationship("Contract", back_populates="resident")
    services = relationship("Service", secondary=using_service, back_populates="residents")


class Contract(Base):
    __tablename__ = "contract"

    id_contract = Column("ID_contract", Integer, primary_key=True, autoincrement=True)
    start_date = Column("Start_date", Date, nullable=False)
    final_date = Column("Final_date", Date, nullable=False)
    summa = Column("Summa", Integer, nullable=False)
    room_id = Column("RoomID_room", Integer, ForeignKey("room.ID_room"), nullable=False)
    manager_id = Column("ManagerID_manager", Integer, ForeignKey("manager.ID_manager"), nullable=False)
    status_of_contract_id = Column(
        "StatusID_status_of_contract",
        Integer,
        ForeignKey("status_of_contract.ID_status_of_contract"),
        nullable=False,
    )
    resident_id = Column("ResidentID_resident", Integer, ForeignKey("resident.ID_resident"), nullable=False)

    manager = relationship("Manager", back_populates="contracts")
    room = relationship("Room", back_populates="contracts")
    resident = relationship("Resident", back_populates="contracts")
    status_of_contract = relationship("StatusOfContract", back_populates="contracts")
