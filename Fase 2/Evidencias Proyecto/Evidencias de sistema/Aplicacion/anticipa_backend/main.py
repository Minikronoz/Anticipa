# =========================================================
# Para correr: uvicorn main:app --reload
# revisar: http://127.0.0.1:8000/docs
# =========================================================
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
import models
import schemas
from database import engine, get_db

# =========================================================
# INICIALIZACIÓN DE TABLAS
# Crea todas las tablas en PostgreSQL si aún no existen.
# =========================================================
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Anticipa",
    description="Backend para la aplicación de rutinas visuales para niños con TEA.",
    version="1.0.0"
)



@app.get("/", tags=["Estado"])
def read_root():
    return {"status": "Backend Anticipa conectado a PostgreSQL exitosamente"}


# =========================================================
# FIX: Ahora recibe un body JSON (RolCreate) en vez de
# un query param, y retorna un schema Pydantic (RolResponse)
# para que FastAPI pueda serializar el objeto correctamente.
# =========================================================
@app.post("/roles/", response_model=schemas.RolResponse, status_code=status.HTTP_201_CREATED, tags=["Roles"])
def crear_rol(rol: schemas.RolCreate, db: Session = Depends(get_db)):
    # Verificar que el rol no exista ya
    existente = db.query(models.Rol).filter(models.Rol.nombre_rol == rol.nombre_rol).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"El rol '{rol.nombre_rol}' ya existe."
        )
    nuevo_rol = models.Rol(nombre_rol=rol.nombre_rol)
    db.add(nuevo_rol)
    db.commit()
    db.refresh(nuevo_rol)
    return nuevo_rol


@app.get("/roles/", response_model=list[schemas.RolResponse], tags=["Roles"])
def listar_roles(db: Session = Depends(get_db)):
    return db.query(models.Rol).all()


# =========================================================
# ENDPOINTS: USUARIO
# =========================================================
@app.post("/usuarios/", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED, tags=["Usuarios"])
def crear_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    existente = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
    if existente:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe un usuario con ese email."
        )
    nuevo_usuario = models.Usuario(**usuario.model_dump())
    db.add(nuevo_usuario)
    db.commit()
    db.refresh(nuevo_usuario)
    return nuevo_usuario


@app.get("/usuarios/", response_model=list[schemas.UsuarioResponse], tags=["Usuarios"])
def listar_usuarios(db: Session = Depends(get_db)):
    return db.query(models.Usuario).all()


@app.get("/usuarios/{id_usuario}", response_model=schemas.UsuarioResponse, tags=["Usuarios"])
def obtener_usuario(id_usuario: int, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.id_usuario == id_usuario).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado.")
    return usuario


# =========================================================
# ENDPOINTS: PICTOGRAMA
# =========================================================
@app.post("/pictogramas/", response_model=schemas.PictogramaResponse, status_code=status.HTTP_201_CREATED, tags=["Pictogramas"])
def crear_pictograma(pictograma: schemas.PictogramaCreate, db: Session = Depends(get_db)):
    nuevo = models.Pictograma(**pictograma.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@app.get("/pictogramas/", response_model=list[schemas.PictogramaResponse], tags=["Pictogramas"])
def listar_pictogramas(db: Session = Depends(get_db)):
    return db.query(models.Pictograma).all()


# =========================================================
# ENDPOINTS: CATALOGO DE ACTIVIDADES
# =========================================================
@app.post("/catalogo/", response_model=schemas.CatalogoActividadResponse, status_code=status.HTTP_201_CREATED, tags=["Catálogo"])
def crear_catalogo(catalogo: schemas.CatalogoActividadCreate, db: Session = Depends(get_db)):
    nuevo = models.CatalogoActividad(**catalogo.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@app.get("/catalogo/", response_model=list[schemas.CatalogoActividadResponse], tags=["Catálogo"])
def listar_catalogo(db: Session = Depends(get_db)):
    return db.query(models.CatalogoActividad).all()


# =========================================================
# ENDPOINTS: ACTIVIDAD
# =========================================================
@app.post("/actividades/", response_model=schemas.ActividadResponse, status_code=status.HTTP_201_CREATED, tags=["Actividades"])
def crear_actividad(actividad: schemas.ActividadCreate, db: Session = Depends(get_db)):
    nueva = models.Actividad(**actividad.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


@app.get("/actividades/estudiante/{id_estudiante}", response_model=list[schemas.ActividadResponse], tags=["Actividades"])
def listar_actividades_estudiante(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.Actividad).filter(models.Actividad.id_estudiante == id_estudiante).all()


@app.patch("/actividades/{id_actividad}/completar", response_model=schemas.ActividadResponse, tags=["Actividades"])
def completar_actividad(id_actividad: int, db: Session = Depends(get_db)):
    actividad = db.query(models.Actividad).filter(models.Actividad.id_actividad == id_actividad).first()
    if not actividad:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Actividad no encontrada.")
    actividad.es_completada = True
    db.commit()
    db.refresh(actividad)
    return actividad


# =========================================================
# ENDPOINTS: HISTORIAL DE CUMPLIMIENTO
# =========================================================
@app.post("/historial/", response_model=schemas.HistorialResponse, status_code=status.HTTP_201_CREATED, tags=["Historial"])
def registrar_cumplimiento(historial: schemas.HistorialCreate, db: Session = Depends(get_db)):
    nuevo = models.HistorialCumplimiento(**historial.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


# =========================================================
# ENDPOINTS: RECOMPENSAS
# =========================================================
@app.post("/recompensas/", response_model=schemas.RecompensaResponse, status_code=status.HTTP_201_CREATED, tags=["Recompensas"])
def crear_recompensa(recompensa: schemas.RecompensaCreate, db: Session = Depends(get_db)):
    nueva = models.RecompensaDisponible(**recompensa.model_dump())
    db.add(nueva)
    db.commit()
    db.refresh(nueva)
    return nueva


@app.get("/recompensas/estudiante/{id_estudiante}", response_model=list[schemas.RecompensaResponse], tags=["Recompensas"])
def listar_recompensas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RecompensaDisponible).filter(
        models.RecompensaDisponible.id_estudiante == id_estudiante
    ).all()


# =========================================================
# ENDPOINTS: ESTRELLAS DIARIAS
# =========================================================
@app.post("/estrellas/", response_model=schemas.EstrellaDiariaResponse, status_code=status.HTTP_201_CREATED, tags=["Estrellas"])
def registrar_estrellas(estrella: schemas.EstrellaDiariaCreate, db: Session = Depends(get_db)):
    nuevo = models.RegistroEstrellaDiaria(**estrella.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo


@app.get("/estrellas/estudiante/{id_estudiante}", response_model=list[schemas.EstrellaDiariaResponse], tags=["Estrellas"])
def listar_estrellas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RegistroEstrellaDiaria).filter(
        models.RegistroEstrellaDiaria.id_estudiante == id_estudiante
    ).all()