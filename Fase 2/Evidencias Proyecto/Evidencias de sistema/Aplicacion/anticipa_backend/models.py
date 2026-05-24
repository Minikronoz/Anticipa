# =========================================================
# MODELS.PY — VERSIÓN FINAL v3
# Proyecto: Anticipa
# CAMBIO PRINCIPAL: Estudiante separado de Usuario.
# Solo 3 roles de usuario: Administrador, Profesor, Tutor.
# =========================================================
import enum
from sqlalchemy import (
    Column, Integer, String, Date, Boolean,
    ForeignKey, Enum, Text, Time,
    CheckConstraint, UniqueConstraint, Index
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql.sqltypes import TIMESTAMP
from sqlalchemy.sql.expression import text
from database import Base


# =========================================================
# 0. TIPOS PERSONALIZADOS (ENUMS)
# values_callable garantiza que SQLAlchemy guarda el VALOR
# del enum ('suave', '5') y no el NOMBRE Python ('suave', 'cinco')
# =========================================================
class TipoSonidoEnum(enum.Enum):
    suave    = 'suave'
    moderado = 'moderado'
    silencio = 'silencio'


class MinutosAnticipacionEnum(enum.Enum):
    dos   = '2'
    cinco = '5'
    diez  = '10'


# =========================================================
# 1. ROL — Solo 3 roles: Administrador, Profesor, Tutor
# =========================================================
class Rol(Base):
    __tablename__ = "rol"

    id_rol     = Column(Integer, primary_key=True, nullable=False)
    nombre_rol = Column(String(50), nullable=False, unique=True)


# =========================================================
# 2. USUARIO — Solo adultos que inician sesión
# Se eliminaron: codigo_vinculacion, puntos_totales,
# curso, fecha_nacimiento (ahora están en Estudiante)
# =========================================================
class Usuario(Base):
    __tablename__ = "usuario"

    id_usuario         = Column(Integer, primary_key=True, nullable=False)
    id_rol             = Column(Integer, ForeignKey("rol.id_rol"), nullable=False)
    nombre             = Column(String(100), nullable=False)
    email              = Column(String(100), nullable=False, unique=True)
    password_hash      = Column(String(255), nullable=False)
    fecha_registro     = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    # Campos para recuperación de contraseña
    reset_token        = Column(String(100), unique=True, nullable=True)
    reset_token_expiry = Column(TIMESTAMP(timezone=True), nullable=True)

    rol            = relationship("Rol")
    vinculaciones  = relationship("VinculacionHistorial", foreign_keys="VinculacionHistorial.id_usuario", back_populates="usuario")


# =========================================================
# 3. ESTUDIANTE — El niño/a con TEA o NEE
# NO tiene email ni contraseña.
# Accede al sistema a través de la cuenta de su tutor.
# =========================================================
class Estudiante(Base):
    __tablename__ = "estudiante"

    id_estudiante      = Column(Integer, primary_key=True, nullable=False)
    nombre             = Column(String(100), nullable=False)
    fecha_nacimiento   = Column(Date, nullable=False)
    curso              = Column(String(100), nullable=True)
    codigo_vinculacion = Column(String(7), unique=True, nullable=True)
    puntos_totales     = Column(Integer, nullable=False, default=0)
    creado_en          = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))

    vinculaciones = relationship("VinculacionHistorial", foreign_keys="VinculacionHistorial.id_estudiante", back_populates="estudiante")
    actividades   = relationship("Actividad", foreign_keys="Actividad.id_estudiante", back_populates="estudiante")


# =========================================================
# 4. VINCULACION_HISTORIAL
# Tabla N:M entre USUARIO (adulto) y ESTUDIANTE (niño).
# CAMBIO: id_estudiante ahora FK a ESTUDIANTE, no a USUARIO.
# Un niño puede tener mamá + papá + profesor vinculados.
# =========================================================
class VinculacionHistorial(Base):
    __tablename__ = "vinculacion_historial"

    id_vinculo    = Column(Integer, primary_key=True, nullable=False)
    id_usuario    = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    id_estudiante = Column(Integer, ForeignKey("estudiante.id_estudiante"), nullable=False)
    fecha_inicio  = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    fecha_termino = Column(TIMESTAMP(timezone=True), nullable=True)
    motivo_cambio = Column(String(255), nullable=True)

    __table_args__ = (
        Index(
            'idx_un_vinculo_activo',
            'id_usuario',
            'id_estudiante',
            unique=True,
            postgresql_where=text('fecha_termino IS NULL')
        ),
    )

    usuario     = relationship("Usuario", foreign_keys=[id_usuario], back_populates="vinculaciones")
    estudiante  = relationship("Estudiante", foreign_keys=[id_estudiante], back_populates="vinculaciones")


# =========================================================
# 5. PICTOGRAMA
# =========================================================
class Pictograma(Base):
    __tablename__ = "pictograma"

    id_pictograma = Column(Integer, primary_key=True, nullable=False)
    nombre_imagen = Column(String(100), nullable=False)
    url           = Column(Text, nullable=False)
    categoria     = Column(String(50), nullable=True)


# =========================================================
# 6. CATALOGO_ACTIVIDAD
# =========================================================
class CatalogoActividad(Base):
    __tablename__ = "catalogo_actividad"

    id_catalogo            = Column(Integer, primary_key=True, nullable=False)
    nombre_predeterminado  = Column(String(100), nullable=False)
    id_pictograma_sugerido = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)

    pictograma = relationship("Pictograma")


# =========================================================
# 7. ACTIVIDAD
# CAMBIO: id_estudiante ahora FK a ESTUDIANTE.
# id_creador sigue siendo FK a USUARIO (el adulto que crea).
# =========================================================
class Actividad(Base):
    __tablename__ = "actividad"

    id_actividad    = Column(Integer, primary_key=True, nullable=False)
    id_estudiante   = Column(Integer, ForeignKey("estudiante.id_estudiante", ondelete="CASCADE"), nullable=False)
    id_creador      = Column(Integer, ForeignKey("usuario.id_usuario"), nullable=False)
    id_pictograma   = Column(Integer, ForeignKey("pictograma.id_pictograma"), nullable=True)
    id_catalogo     = Column(Integer, ForeignKey("catalogo_actividad.id_catalogo"), nullable=True)
    nombre_tarea    = Column(String(100), nullable=False)
    hora_inicio     = Column(Time, nullable=False)
    hora_fin        = Column(Time, nullable=False)
    es_completada   = Column(Boolean, nullable=False, default=False)
    fecha_actividad = Column(Date, nullable=False)
    fecha_creacion  = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))

    estudiante = relationship("Estudiante", foreign_keys=[id_estudiante], back_populates="actividades")
    creador    = relationship("Usuario", foreign_keys=[id_creador])
    pictograma = relationship("Pictograma")
    catalogo   = relationship("CatalogoActividad")


# =========================================================
# 8. CONFIGURACION_ALERTA — Sin cambios
# =========================================================
class ConfiguracionAlerta(Base):
    __tablename__ = "configuracion_alerta"

    id_alerta            = Column(Integer, primary_key=True, nullable=False)
    id_actividad         = Column(Integer, ForeignKey("actividad.id_actividad", ondelete="CASCADE"), nullable=False, unique=True)
    minutos_anticipacion = Column(
        Enum(MinutosAnticipacionEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=MinutosAnticipacionEnum.cinco
    )
    tipo_sonido = Column(
        Enum(TipoSonidoEnum, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        default=TipoSonidoEnum.suave
    )
    parpadeo_visual = Column(Boolean, nullable=False, default=True)

    actividad = relationship("Actividad")


# =========================================================
# 9. RECOMPENSA_DISPONIBLE
# CAMBIO: id_estudiante ahora FK a ESTUDIANTE.
# =========================================================
class RecompensaDisponible(Base):
    __tablename__ = "recompensa_disponible"

    id_recompensa     = Column(Integer, primary_key=True, nullable=False)
    id_estudiante     = Column(Integer, ForeignKey("estudiante.id_estudiante", ondelete="CASCADE"), nullable=False)
    nombre_recompensa = Column(String(100), nullable=False)
    recompensa_url    = Column(Text, nullable=True)
    meta_estrellas    = Column(Integer, nullable=False, default=5)
    estado_logro      = Column(Boolean, nullable=False, default=False)
    fecha_logro       = Column(TIMESTAMP(timezone=True), nullable=True)

    estudiante = relationship("Estudiante")


# =========================================================
# 10. REGISTRO_ESTRELLA_DIARIA
# CAMBIO: id_estudiante ahora FK a ESTUDIANTE.
# =========================================================
class RegistroEstrellaDiaria(Base):
    __tablename__ = "registro_estrella_diaria"

    id_registro       = Column(Integer, primary_key=True, nullable=False)
    id_estudiante     = Column(Integer, ForeignKey("estudiante.id_estudiante"), nullable=False)
    fecha             = Column(Date, nullable=False, server_default=text('CURRENT_DATE'))
    estrellas_ganadas = Column(Integer, nullable=False, default=0)

    __table_args__ = (
        CheckConstraint('estrellas_ganadas >= 0', name='check_estrellas_positivas'),
        UniqueConstraint('id_estudiante', 'fecha', name='unq_estudiante_fecha'),
    )

    estudiante = relationship("Estudiante")


# =========================================================
# 11. HISTORIAL_CUMPLIMIENTO — Sin cambios
# =========================================================
class HistorialCumplimiento(Base):
    __tablename__ = "historial_cumplimiento"

    id_log             = Column(Integer, primary_key=True, nullable=False)
    id_actividad       = Column(Integer, ForeignKey("actividad.id_actividad"), nullable=False)
    fecha_cumplimiento = Column(TIMESTAMP(timezone=True), nullable=False, server_default=text('now()'))
    observaciones      = Column(String(255), nullable=True)

    actividad = relationship("Actividad")