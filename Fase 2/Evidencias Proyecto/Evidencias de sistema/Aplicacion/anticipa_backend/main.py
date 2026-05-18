# =========================================================
# MAIN.PY — SERVIDOR FASTAPI
# Para correr: uvicorn main:app --reload
# Documentación: http://127.0.0.1:8000/docs
# =========================================================
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
import models
import schemas
from database import engine, get_db
import random
import string
from passlib.context import CryptContext
from datetime import datetime, timedelta
from dotenv import load_dotenv
from pathlib import Path
import os

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

models.Base.metadata.create_all(bind=engine)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def generar_codigo_vinculacion(length: int = 7) -> str:
    characters = string.ascii_uppercase + string.digits
    return ''.join(random.choices(characters, k=length))

def generar_codigo_recuperacion(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))

def enviar_codigo_email(email: str, codigo: str):
    try:
        import yagmail
        email_user = os.getenv("EMAIL_USER")
        email_password = os.getenv("EMAIL_PASSWORD")
        email_from = os.getenv("EMAIL_FROM", "Anticipa App")
        
        yag = yagmail.SMTP(email_user, email_password)
        
        asunto = "Código de recuperación de contraseña - Anticipa"
        contenido = f"""
        Hola,

        Has solicitado recuperar tu contraseña en Anticipa.

        Tu código de verificación es: {codigo}

        Este código expires en 15 minutos.

        Si no fuiste tú, ignora este mensaje.

        Saludos,
        Equipo Anticipa
        """
        
        yag.send(to=email, subject=asunto, contents=contenido)
        return True
    except Exception as e:
        print(f"Error al enviar email: {e}")
        return False

app = FastAPI(
    title="API Anticipa",
    description="Backend para la aplicación de rutinas visuales para niños con TEA.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Estado"])
def read_root():
    return {"status": "Backend Anticipa conectado a PostgreSQL exitosamente"}

# =========================================================
# AUTENTICACIÓN
# =========================================================
@app.post("/auth/login", tags=["Autenticación"])
def iniciar_sesion(request: schemas.LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == request.email).first()
    if not usuario or not verify_password(request.password, usuario.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Email o contraseña incorrectos")
    rol = db.query(models.Rol).filter(models.Rol.id_rol == usuario.id_rol).first()
    return {
        "mensaje": "Login exitoso",
        "id_usuario": usuario.id_usuario,
        "nombre": usuario.nombre,
        "rol": rol.nombre_rol,
        "id_rol": usuario.id_rol
    }

# RECUPERACIÓN DE CONTRASEÑA
# =========================================================
@app.post("/auth/solicitar-codigo", tags=["Autenticación"])
def solicitar_codigo_recuperacion(request: schemas.RecuperarPasswordRequest, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == request.email).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No existe ninguna cuenta con este correo.")
    
    codigo = generar_codigo_recuperacion()
    expiration = datetime.now() + timedelta(minutes=15)
    
    usuario.codigo_recuperacion = codigo
    usuario.codigo_expiracion = expiration
    db.commit()
    
    if enviar_codigo_email(usuario.email, codigo):
        return {"mensaje": "Código enviado a tu correo electrónico."}
    else:
        return {"mensaje": "Código generado (modo desarrollo): " + codigo}


@app.post("/auth/verificar-codigo", tags=["Autenticación"])
def verificar_codigo(request: schemas.VerificarCodigoRequest, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == request.email).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado.")
    
    if not usuario.codigo_recuperacion or not usuario.codigo_expiracion:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No hay código de recuperación activo. Solicita uno nuevo.")
    
    if usuario.codigo_recuperacion != request.codigo:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código incorrecto.")
    
    if datetime.now() > usuario.codigo_expiracion:
        usuario.codigo_recuperacion = None
        usuario.codigo_expiracion = None
        db.commit()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El código ha expirado. Solicita uno nuevo.")
    
    return {"mensaje": "Código verificado correctamente."}


@app.post("/auth/cambiar-password", tags=["Autenticación"])
def cambiar_password(request: schemas.CambiarPasswordRequest, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(models.Usuario.email == request.email).first()
    if not usuario:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Usuario no encontrado.")
    
    if not usuario.codigo_recuperacion or not usuario.codigo_expiracion:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Debes verificar el código primero.")
    
    if usuario.codigo_recuperacion != request.codigo:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código incorrecto.")
    
    if datetime.now() > usuario.codigo_expiracion:
        usuario.codigo_recuperacion = None
        usuario.codigo_expiracion = None
        db.commit()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="El código ha expirado. Solicita uno nuevo.")
    
    usuario.password_hash = hash_password(request.nueva_password)
    usuario.codigo_recuperacion = None
    usuario.codigo_expiracion = None
    db.commit()
    
    return {"mensaje": "Contraseña actualizada correctamente."}

# =========================================================
# ROLES
# =========================================================
@app.post("/roles/", response_model=schemas.RolResponse, status_code=status.HTTP_201_CREATED, tags=["Roles"])
def crear_rol(rol: schemas.RolCreate, db: Session = Depends(get_db)):
    existente = db.query(models.Rol).filter(models.Rol.nombre_rol == rol.nombre_rol).first()
    if existente:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=f"El rol '{rol.nombre_rol}' ya existe.")
    nuevo_rol = models.Rol(nombre_rol=rol.nombre_rol)
    db.add(nuevo_rol)
    db.commit()
    db.refresh(nuevo_rol)
    return nuevo_rol

@app.get("/roles/", response_model=list[schemas.RolResponse], tags=["Roles"])
def listar_roles(db: Session = Depends(get_db)):
    return db.query(models.Rol).all()

# =========================================================
# USUARIOS
# =========================================================
@app.post("/usuarios/", response_model=schemas.UsuarioResponse, status_code=status.HTTP_201_CREATED, tags=["Usuarios"])
def crear_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    existente = db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first()
    if existente:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Ya existe un usuario con ese email.")
    
    usuario_data = usuario.model_dump()
    usuario_data['password_hash'] = hash_password(usuario_data['password_hash'])
    
    if usuario.id_rol == 4:
        usuario_data['codigo_vinculacion'] = generar_codigo_vinculacion()
    else:
        usuario_data['codigo_vinculacion'] = None
    
    nuevo_usuario = models.Usuario(**usuario_data)
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
# PICTOGRAMAS
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
# CATÁLOGO
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
# ACTIVIDADES
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
# HISTORIAL
# =========================================================
@app.post("/historial/", response_model=schemas.HistorialResponse, status_code=status.HTTP_201_CREATED, tags=["Historial"])
def registrar_cumplimiento(historial: schemas.HistorialCreate, db: Session = Depends(get_db)):
    nuevo = models.HistorialCumplimiento(**historial.model_dump())
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)
    return nuevo

# =========================================================
# RECOMPENSAS
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
    return db.query(models.RecompensaDisponible).filter(models.RecompensaDisponible.id_estudiante == id_estudiante).all()

# =========================================================
# ESTRELLAS DIARIAS
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
    return db.query(models.RegistroEstrellaDiaria).filter(models.RegistroEstrellaDiaria.id_estudiante == id_estudiante).all()