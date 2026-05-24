# =========================================================
# MAIN.PY — VERSIÓN FINAL
# Proyecto: Anticipa
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
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from pathlib import Path
import os

env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

models.Base.metadata.create_all(bind=engine)

# ── Utilidades ───────────────────────────────────────────
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def generar_codigo_vinculacion(length: int = 7) -> str:
    """Genera código único para vincular adultos al estudiante."""
    characters = string.ascii_uppercase + string.digits
    return ''.join(random.choices(characters, k=length))

def generar_codigo_recuperacion(length: int = 6) -> str:
    """Genera código numérico de 6 dígitos para recuperar contraseña."""
    return ''.join(random.choices(string.digits, k=length))

def enviar_codigo_email(email: str, codigo: str, nombre: str = ""):
    """Envía el código de recuperación por correo usando yagmail."""
    try:
        import yagmail
        email_user     = os.getenv("EMAIL_USER")
        email_password = os.getenv("EMAIL_PASSWORD")

        yag = yagmail.SMTP(email_user, email_password)

        asunto = "Código de recuperación de contraseña — Anticipa"
        contenido = f"""
        <html><body style="font-family:Arial,sans-serif;max-width:480px;margin:auto">
          <div style="background:#1F4E79;padding:20px;border-radius:8px 8px 0 0">
            <h1 style="color:white;margin:0">Anticipa</h1>
          </div>
          <div style="background:#f8f9fa;padding:24px;border-radius:0 0 8px 8px">
            <h2 style="color:#1F4E79">Recuperar Contraseña</h2>
            <p>Hola{' ' + nombre if nombre else ''},</p>
            <p>Tu código de verificación es:</p>
            <div style="text-align:center;margin:24px 0">
              <span style="font-size:36px;font-weight:bold;letter-spacing:8px;
                    color:#1F4E79;background:#DEEAF1;padding:16px 24px;border-radius:8px">
                {codigo}
              </span>
            </div>
            <p style="color:#888;font-size:13px">
              ⏱ Este código expira en <strong>15 minutos</strong>.<br>
              Si no fuiste tú, ignora este mensaje.
            </p>
          </div>
        </body></html>
        """

        yag.send(to=email, subject=asunto, contents=contenido)
        return True
    except Exception as e:
        print(f"Error al enviar email: {e}")
        return False


# ── App ──────────────────────────────────────────────────
app = FastAPI(
    title="API Anticipa",
    description="Backend para la aplicación de rutinas visuales para niños con TEA.",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# =========================================================
# HEALTH CHECK
# =========================================================
@app.get("/", tags=["Estado"])
def read_root():
    return {"status": "Backend Anticipa conectado a PostgreSQL exitosamente"}


# =========================================================
# AUTENTICACIÓN
# =========================================================
@app.post("/auth/login", tags=["Autenticación"])
def iniciar_sesion(request: schemas.LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(models.Usuario).filter(
        models.Usuario.email == request.email
    ).first()
    if not usuario or not verify_password(request.password, usuario.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos"
        )
    rol = db.query(models.Rol).filter(models.Rol.id_rol == usuario.id_rol).first()
    return {
        "mensaje":    "Login exitoso",
        "id_usuario": usuario.id_usuario,
        "nombre":     usuario.nombre,
        "rol":        rol.nombre_rol,
        "id_rol":     usuario.id_rol
    }


# ── Recuperación de contraseña (3 pasos) ─────────────────

@app.post("/auth/solicitar-codigo", tags=["Autenticación"])
def solicitar_codigo_recuperacion(
    request: schemas.RecuperarPasswordRequest,
    db: Session = Depends(get_db)
):
    usuario = db.query(models.Usuario).filter(
        models.Usuario.email == request.email
    ).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="No existe ninguna cuenta con este correo.")

    codigo     = generar_codigo_recuperacion()
    expiracion = datetime.now() + timedelta(minutes=15)

    usuario.reset_token = codigo
    usuario.reset_token_expiry   = expiracion
    db.commit()

    if enviar_codigo_email(usuario.email, codigo, usuario.nombre):
        return {"mensaje": "Código enviado a tu correo electrónico."}
    else:
        # En desarrollo: devuelve el código si el email falla
        return {"mensaje": f"[DEV] Código generado: {codigo}"}


@app.post("/auth/verificar-codigo", tags=["Autenticación"])
def verificar_codigo(
    request: schemas.VerificarCodigoRequest,
    db: Session = Depends(get_db)
):
    usuario = db.query(models.Usuario).filter(
        models.Usuario.email == request.email
    ).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    if not usuario.reset_token or not usuario.reset_token_expiry:
        raise HTTPException(status_code=400, detail="No hay código activo. Solicita uno nuevo.")
    if usuario.reset_token != request.codigo:
        raise HTTPException(status_code=400, detail="Código incorrecto.")
    if datetime.now() > usuario.reset_token_expiry:
        usuario.reset_token = None
        usuario.reset_token_expiry   = None
        db.commit()
        raise HTTPException(status_code=400, detail="El código ha expirado. Solicita uno nuevo.")

    return {"mensaje": "Código verificado correctamente."}


@app.post("/auth/cambiar-password", tags=["Autenticación"])
def cambiar_password(
    request: schemas.CambiarPasswordRequest,
    db: Session = Depends(get_db)
):
    usuario = db.query(models.Usuario).filter(
        models.Usuario.email == request.email
    ).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    if not usuario.reset_token or not usuario.reset_token_expiry:
        raise HTTPException(status_code=400, detail="Debes verificar el código primero.")
    if usuario.reset_token != request.codigo:
        raise HTTPException(status_code=400, detail="Código incorrecto.")
    if datetime.now() > usuario.reset_token_expiry:
        usuario.reset_token = None
        usuario.reset_token_expiry   = None
        db.commit()
        raise HTTPException(status_code=400, detail="El código ha expirado. Solicita uno nuevo.")

    usuario.password_hash       = hash_password(request.nueva_password)
    usuario.reset_token = None
    usuario.reset_token_expiry   = None
    db.commit()

    return {"mensaje": "Contraseña actualizada correctamente."}


# =========================================================
# ROLES
# =========================================================
@app.post("/roles/", response_model=schemas.RolResponse,
          status_code=status.HTTP_201_CREATED, tags=["Roles"])
def crear_rol(rol: schemas.RolCreate, db: Session = Depends(get_db)):
    if db.query(models.Rol).filter(models.Rol.nombre_rol == rol.nombre_rol).first():
        raise HTTPException(status_code=409, detail=f"El rol '{rol.nombre_rol}' ya existe.")
    nuevo = models.Rol(nombre_rol=rol.nombre_rol)
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/roles/", response_model=list[schemas.RolResponse], tags=["Roles"])
def listar_roles(db: Session = Depends(get_db)):
    return db.query(models.Rol).all()


# =========================================================
# USUARIOS (solo adultos: Admin, Profesor, Tutor)
# CAMBIO: Se eliminó la generación de codigo_vinculacion
# en usuarios. Ahora el código se genera en el ESTUDIANTE.
# =========================================================
@app.post("/usuarios/", response_model=schemas.UsuarioResponse,
          status_code=status.HTTP_201_CREATED, tags=["Usuarios"])
def crear_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first():
        raise HTTPException(status_code=409, detail="Ya existe un usuario con ese email.")

    usuario_data = usuario.model_dump()
    # Hashear la contraseña antes de guardar
    usuario_data['password_hash'] = hash_password(usuario_data['password_hash'])

    nuevo = models.Usuario(**usuario_data)
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/usuarios/", response_model=list[schemas.UsuarioResponse], tags=["Usuarios"])
def listar_usuarios(db: Session = Depends(get_db)):
    return db.query(models.Usuario).all()

@app.get("/usuarios/{id_usuario}", response_model=schemas.UsuarioResponse, tags=["Usuarios"])
def obtener_usuario(id_usuario: int, db: Session = Depends(get_db)):
    u = db.query(models.Usuario).filter(models.Usuario.id_usuario == id_usuario).first()
    if not u:
        raise HTTPException(status_code=404, detail="Usuario no encontrado.")
    return u


# =========================================================
# ESTUDIANTES (los niños/as — no inician sesión)
# Acceden al sistema a través de la cuenta de su tutor.
# =========================================================
@app.post("/estudiantes/", response_model=schemas.EstudianteResponse,
          status_code=status.HTTP_201_CREATED, tags=["Estudiantes"])
def crear_estudiante(estudiante: schemas.EstudianteCreate, db: Session = Depends(get_db)):
    datos = estudiante.model_dump()
    # Generar código de vinculación único automáticamente
    while True:
        codigo = generar_codigo_vinculacion()
        if not db.query(models.Estudiante).filter(
            models.Estudiante.codigo_vinculacion == codigo
        ).first():
            break
    datos['codigo_vinculacion'] = codigo

    nuevo = models.Estudiante(**datos)
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/estudiantes/", response_model=list[schemas.EstudianteResponse], tags=["Estudiantes"])
def listar_estudiantes(db: Session = Depends(get_db)):
    return db.query(models.Estudiante).all()

@app.get("/estudiantes/{id_estudiante}", response_model=schemas.EstudianteResponse, tags=["Estudiantes"])
def obtener_estudiante(id_estudiante: int, db: Session = Depends(get_db)):
    e = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == id_estudiante
    ).first()
    if not e:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado.")
    return e

@app.get("/estudiantes/usuario/{id_usuario}",
         response_model=list[schemas.EstudianteResponse], tags=["Estudiantes"])
def estudiantes_de_usuario(id_usuario: int, db: Session = Depends(get_db)):
    """Devuelve todos los estudiantes vinculados activamente a un adulto.
    Usado por Flutter para mostrar la pantalla tipo Netflix al hacer login."""
    vinculos = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_usuario    == id_usuario,
        models.VinculacionHistorial.fecha_termino == None
    ).all()
    return [v.estudiante for v in vinculos]

@app.patch("/estudiantes/{id_estudiante}",
           response_model=schemas.EstudianteResponse, tags=["Estudiantes"])
def actualizar_estudiante(
    id_estudiante: int,
    datos: schemas.EstudianteUpdate,
    db: Session = Depends(get_db)
):
    e = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == id_estudiante
    ).first()
    if not e:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado.")
    for campo, valor in datos.model_dump(exclude_unset=True).items():
        setattr(e, campo, valor)
    db.commit(); db.refresh(e)
    return e


# =========================================================
# VINCULACIONES (adulto ↔ estudiante)
# =========================================================
@app.post("/vinculaciones/", response_model=schemas.VinculacionResponse,
          status_code=status.HTTP_201_CREATED, tags=["Vinculaciones"])
def crear_vinculacion(v: schemas.VinculacionCreate, db: Session = Depends(get_db)):
    existente = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_usuario    == v.id_usuario,
        models.VinculacionHistorial.id_estudiante == v.id_estudiante,
        models.VinculacionHistorial.fecha_termino == None
    ).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya existe un vínculo activo entre este usuario y estudiante.")
    nuevo = models.VinculacionHistorial(**v.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.post("/vinculaciones/codigo/{codigo}",
          response_model=schemas.VinculacionResponse,
          status_code=status.HTTP_201_CREATED, tags=["Vinculaciones"])
def vincular_por_codigo(codigo: str, id_usuario: int, db: Session = Depends(get_db)):
    """Vincula un adulto a un estudiante usando el código de vinculación del niño.
    El tutor/profesor recibe este código y lo ingresa en la app para conectarse."""
    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.codigo_vinculacion == codigo.upper()
    ).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Código de vinculación inválido.")
    existente = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_usuario    == id_usuario,
        models.VinculacionHistorial.id_estudiante == estudiante.id_estudiante,
        models.VinculacionHistorial.fecha_termino == None
    ).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya estás vinculado a este estudiante.")
    nuevo = models.VinculacionHistorial(
        id_usuario    = id_usuario,
        id_estudiante = estudiante.id_estudiante
    )
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/vinculaciones/usuario/{id_usuario}",
         response_model=list[schemas.VinculacionResponse], tags=["Vinculaciones"])
def listar_vinculaciones(id_usuario: int, db: Session = Depends(get_db)):
    return db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_usuario == id_usuario
    ).all()

@app.patch("/vinculaciones/{id_vinculo}/desvincular",
           response_model=schemas.VinculacionResponse, tags=["Vinculaciones"])
def desvincular(
    id_vinculo: int,
    motivo: str = "Desvinculación manual",
    db: Session = Depends(get_db)
):
    """Cierra un vínculo activo registrando la fecha de término (HU05)."""
    v = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_vinculo == id_vinculo
    ).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vínculo no encontrado.")
    if v.fecha_termino:
        raise HTTPException(status_code=409, detail="Este vínculo ya está inactivo.")
    v.fecha_termino = datetime.now(timezone.utc)
    v.motivo_cambio = motivo
    db.commit(); db.refresh(v)
    return v


# =========================================================
# PICTOGRAMAS
# =========================================================
@app.post("/pictogramas/", response_model=schemas.PictogramaResponse,
          status_code=status.HTTP_201_CREATED, tags=["Pictogramas"])
def crear_pictograma(pictograma: schemas.PictogramaCreate, db: Session = Depends(get_db)):
    nuevo = models.Pictograma(**pictograma.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/pictogramas/", response_model=list[schemas.PictogramaResponse], tags=["Pictogramas"])
def listar_pictogramas(db: Session = Depends(get_db)):
    return db.query(models.Pictograma).all()


# =========================================================
# CATÁLOGO DE ACTIVIDADES
# =========================================================
@app.post("/catalogo/", response_model=schemas.CatalogoActividadResponse,
          status_code=status.HTTP_201_CREATED, tags=["Catálogo"])
def crear_catalogo(catalogo: schemas.CatalogoActividadCreate, db: Session = Depends(get_db)):
    nuevo = models.CatalogoActividad(**catalogo.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/catalogo/", response_model=list[schemas.CatalogoActividadResponse], tags=["Catálogo"])
def listar_catalogo(db: Session = Depends(get_db)):
    return db.query(models.CatalogoActividad).all()


# =========================================================
# ACTIVIDADES
# =========================================================
@app.post("/actividades/", response_model=schemas.ActividadResponse,
          status_code=status.HTTP_201_CREATED, tags=["Actividades"])
def crear_actividad(actividad: schemas.ActividadCreate, db: Session = Depends(get_db)):
    nueva = models.Actividad(**actividad.model_dump())
    db.add(nueva); db.commit(); db.refresh(nueva)
    return nueva

@app.get("/actividades/estudiante/{id_estudiante}",
         response_model=list[schemas.ActividadResponse], tags=["Actividades"])
def listar_actividades_estudiante(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.Actividad).filter(
        models.Actividad.id_estudiante == id_estudiante
    ).all()

@app.patch("/actividades/{id_actividad}/completar",
           response_model=schemas.ActividadResponse, tags=["Actividades"])
def completar_actividad(id_actividad: int, db: Session = Depends(get_db)):
    a = db.query(models.Actividad).filter(
        models.Actividad.id_actividad == id_actividad
    ).first()
    if not a:
        raise HTTPException(status_code=404, detail="Actividad no encontrada.")
    a.es_completada = True
    db.commit(); db.refresh(a)
    return a


# =========================================================
# HISTORIAL DE CUMPLIMIENTO
# =========================================================
@app.post("/historial/", response_model=schemas.HistorialResponse,
          status_code=status.HTTP_201_CREATED, tags=["Historial"])
def registrar_cumplimiento(historial: schemas.HistorialCreate, db: Session = Depends(get_db)):
    nuevo = models.HistorialCumplimiento(**historial.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/historial/estudiante/{id_estudiante}",
         response_model=list[schemas.HistorialResponse], tags=["Historial"])
def historial_estudiante(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.HistorialCumplimiento).join(models.Actividad).filter(
        models.Actividad.id_estudiante == id_estudiante
    ).all()


# =========================================================
# RECOMPENSAS
# =========================================================
@app.post("/recompensas/", response_model=schemas.RecompensaResponse,
          status_code=status.HTTP_201_CREATED, tags=["Recompensas"])
def crear_recompensa(recompensa: schemas.RecompensaCreate, db: Session = Depends(get_db)):
    nueva = models.RecompensaDisponible(**recompensa.model_dump())
    db.add(nueva); db.commit(); db.refresh(nueva)
    return nueva

@app.get("/recompensas/estudiante/{id_estudiante}",
         response_model=list[schemas.RecompensaResponse], tags=["Recompensas"])
def listar_recompensas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RecompensaDisponible).filter(
        models.RecompensaDisponible.id_estudiante == id_estudiante
    ).all()


# =========================================================
# ESTRELLAS DIARIAS
# =========================================================
@app.post("/estrellas/", response_model=schemas.EstrellaDiariaResponse,
          status_code=status.HTTP_201_CREATED, tags=["Estrellas"])
def registrar_estrellas(estrella: schemas.EstrellaDiariaCreate, db: Session = Depends(get_db)):
    nuevo = models.RegistroEstrellaDiaria(**estrella.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/estrellas/estudiante/{id_estudiante}",
         response_model=list[schemas.EstrellaDiariaResponse], tags=["Estrellas"])
def listar_estrellas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RegistroEstrellaDiaria).filter(
        models.RegistroEstrellaDiaria.id_estudiante == id_estudiante
    ).all()