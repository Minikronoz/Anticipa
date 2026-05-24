# =========================================================
# SCHEMAS.PY — VERSIÓN FINAL v2
# Proyecto: Anticipa
# Esquemas Pydantic para validación y serialización.
# CAMBIO: Nueva entidad Estudiante separada de Usuario.
# =========================================================
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import date, datetime, time
from models import TipoSonidoEnum, MinutosAnticipacionEnum


class ConfigBase(BaseModel):
    class Config:
        from_attributes = True  
        use_enum_values  = True  

# =========================================================
# 1. ROL
# =========================================================
class RolCreate(ConfigBase):
    nombre_rol: str

class RolResponse(ConfigBase):
    id_rol:     int
    nombre_rol: str


# =========================================================
# 2. USUARIO — Solo adultos (Admin, Profesor, Tutor)
# Se eliminaron campos del estudiante del schema
# =========================================================
class UsuarioCreate(ConfigBase):
    id_rol:        int
    nombre:        str
    email:         EmailStr
    password_hash: str

class UsuarioResponse(ConfigBase):
    id_usuario:    int
    id_rol:        int
    nombre:        str
    email:         str
    fecha_registro: datetime
    # Nunca se expone password_hash ni reset_token


# =========================================================
# 3. ESTUDIANTE — El niño, no inicia sesión
# =========================================================
class EstudianteCreate(ConfigBase):
    nombre:             str
    fecha_nacimiento:   date
    curso:              Optional[str] = None
    codigo_vinculacion: Optional[str] = None

class EstudianteResponse(ConfigBase):
    id_estudiante:      int
    nombre:             str
    fecha_nacimiento:   date
    curso:              Optional[str]
    codigo_vinculacion: Optional[str]
    puntos_totales:     int
    creado_en:          datetime

class EstudianteUpdate(ConfigBase):
    nombre:             Optional[str] = None
    fecha_nacimiento:   Optional[date] = None
    curso:              Optional[str] = None


# =========================================================
# 4. VINCULACION_HISTORIAL
# CAMBIO: id_adulto → id_usuario (adulto vinculado al niño)
# =========================================================
class VinculacionCreate(ConfigBase):
    id_usuario:    int   # El adulto (Tutor o Profesor)
    id_estudiante: int   # El niño
    motivo_cambio: Optional[str] = None

class VinculacionResponse(ConfigBase):
    id_vinculo:    int
    id_usuario:    int
    id_estudiante: int
    fecha_inicio:  datetime
    fecha_termino: Optional[datetime]
    motivo_cambio: Optional[str]


# =========================================================
# 5. PICTOGRAMA
# =========================================================
class PictogramaCreate(ConfigBase):
    nombre_imagen: str
    url:           str
    categoria:     Optional[str] = None

class PictogramaResponse(ConfigBase):
    id_pictograma: int
    nombre_imagen: str
    url:           str
    categoria:     Optional[str]


# =========================================================
# 6. CATALOGO_ACTIVIDAD
# =========================================================
class CatalogoActividadCreate(ConfigBase):
    nombre_predeterminado:  str
    id_pictograma_sugerido: Optional[int] = None

class CatalogoActividadResponse(ConfigBase):
    id_catalogo:            int
    nombre_predeterminado:  str
    id_pictograma_sugerido: Optional[int]


# =========================================================
# 7. ACTIVIDAD
# CAMBIO: id_estudiante referencia a Estudiante
# =========================================================
class ActividadCreate(ConfigBase):
    id_estudiante:   int
    id_creador:      int
    id_pictograma:   Optional[int] = None
    id_catalogo:     Optional[int] = None
    nombre_tarea:    str
    hora_inicio:     time
    hora_fin:        time
    fecha_actividad: date

class ActividadResponse(ConfigBase):
    id_actividad:    int
    id_estudiante:   int
    id_creador:      int
    id_pictograma:   Optional[int]
    id_catalogo:     Optional[int]
    nombre_tarea:    str
    hora_inicio:     time
    hora_fin:        time
    es_completada:   bool
    fecha_actividad: date
    fecha_creacion:  datetime


# =========================================================
# 8. CONFIGURACION_ALERTA
# =========================================================
class ConfiguracionAlertaCreate(ConfigBase):
    id_actividad:         int
    minutos_anticipacion: MinutosAnticipacionEnum = MinutosAnticipacionEnum.cinco
    tipo_sonido:          TipoSonidoEnum          = TipoSonidoEnum.suave
    parpadeo_visual:      bool                    = True

class ConfiguracionAlertaResponse(ConfigBase):
    id_alerta:            int
    id_actividad:         int
    minutos_anticipacion: str
    tipo_sonido:          str
    parpadeo_visual:      bool


# =========================================================
# 9. RECOMPENSA_DISPONIBLE
# CAMBIO: id_estudiante referencia a Estudiante
# =========================================================
class RecompensaCreate(ConfigBase):
    id_estudiante:     int
    nombre_recompensa: str
    recompensa_url:    Optional[str] = None
    meta_estrellas:    int           = 5

class RecompensaResponse(ConfigBase):
    id_recompensa:     int
    id_estudiante:     int
    nombre_recompensa: str
    recompensa_url:    Optional[str]
    meta_estrellas:    int
    estado_logro:      bool
    fecha_logro:       Optional[datetime]


# =========================================================
# 10. REGISTRO_ESTRELLA_DIARIA
# CAMBIO: id_estudiante referencia a Estudiante
# =========================================================
class EstrellaDiariaCreate(ConfigBase):
    id_estudiante:     int
    fecha:             date
    estrellas_ganadas: int = 0

class EstrellaDiariaResponse(ConfigBase):
    id_registro:       int
    id_estudiante:     int
    fecha:             date
    estrellas_ganadas: int


# =========================================================
# 11. HISTORIAL_CUMPLIMIENTO
# =========================================================
class HistorialCreate(ConfigBase):
    id_actividad:  int
    observaciones: Optional[str] = None

class HistorialResponse(ConfigBase):
    id_log:             int
    id_actividad:       int
    fecha_cumplimiento: datetime
    observaciones:      Optional[str]


# =========================================================
# AUTENTICACIÓN
# =========================================================
class LoginRequest(BaseModel):
    email:    str
    password: str

class RecuperarPasswordRequest(BaseModel):
    email: str



class VerificarCodigoRequest(BaseModel):
    email: str
    codigo: str

class CambiarPasswordRequest(BaseModel):
    email: str
    codigo: str
    nueva_password: str