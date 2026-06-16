from fastapi import FastAPI, Depends, HTTPException, status, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session, selectinload
import models
import schemas
from database import engine, get_db
import random
import string
import re
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone, date
from zoneinfo import ZoneInfo

CHILE_TZ = ZoneInfo("America/Santiago")
from dotenv import load_dotenv
from pathlib import Path
import os
from admin import router as admin_router
from collections import Counter
from fastapi.responses import FileResponse, StreamingResponse
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet
import io




# ── Configuración inicial ──────────────────────────────────
env_path = Path(__file__).parent / '.env'
load_dotenv(dotenv_path=env_path)

from sqlalchemy import text

models.Base.metadata.create_all(bind=engine)

# Sincronizar secuencias SERIAL (evita UniqueViolation al insertar)
with engine.connect() as conn:
    conn.execute(text("""
        DO $$
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN
                SELECT table_name, column_name
                FROM information_schema.columns
                WHERE table_schema = 'public'
                  AND column_default LIKE 'nextval%'
            LOOP
                EXECUTE format('SELECT setval(pg_get_serial_sequence(''%I'', ''%I''), COALESCE(MAX(%I), 1)) FROM %I',
                    r.table_name, r.column_name, r.column_name, r.table_name);
            END LOOP;
        END $$;
    """))
    conn.commit()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ── Utilidades: hash, email, códigos ──────────────────────
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def generar_codigo_vinculacion(length: int = 7) -> str:
    characters = string.ascii_uppercase + string.digits
    return ''.join(random.choices(characters, k=length))

def generar_codigo_recuperacion(length: int = 6) -> str:
    return ''.join(random.choices(string.digits, k=length))

def enviar_codigo_email(email: str, codigo: str, nombre: str = ""):
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

# ── Detección de rol por dominio de email (registro automático) ──
ALLOWED_DOMAINS = {
    'gmail.com': 3,
    'outlook.com': 3,
    'profesor.cl': 2,
    'estudiante.cl': 4,
    'duocuc.cl': 4,
}

def detectar_rol_por_email(email: str) -> int:
    try:
        domain = email.split('@')[1].lower()
    except (IndexError, ValueError):
        raise HTTPException(status_code=400, detail="Formato de correo inválido.")
    if domain not in ALLOWED_DOMAINS:
        raise HTTPException(
            status_code=400,
            detail=f"Dominio de correo no autorizado: {domain}. Usa @gmail.com, @outlook.com, @profesor.cl, @estudiante.cl o @duocuc.cl"
        )
    return ALLOWED_DOMAINS[domain]

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
    rol = db.query(models.Rol).filter(models.Rol.id_rol == usuario.rol_id_rol).first()
    respuesta = {
        "mensaje":    "Login exitoso",
        "id_usuario": usuario.id_usuario,
        "nombre":     usuario.nombre,
        "rol":        rol.nombre_rol,
        "rol_id_rol": usuario.rol_id_rol,
    }
    if usuario.rol_id_rol == 4:
        estudiante = db.query(models.Estudiante).filter(
            models.Estudiante.usuario_id_usuario == usuario.id_usuario
        ).first()
        if estudiante:
            respuesta["id_estudiante"] = estudiante.id_estudiante
    return respuesta


# ── Recuperación de contraseña ────────────────────────────

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
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=15)

    usuario.reset_token = codigo
    usuario.reset_token_expiry   = expiracion
    db.commit()

    if enviar_codigo_email(usuario.email, codigo, usuario.nombre):
        return {"mensaje": "Código enviado a tu correo electrónico."}
    else:
        return {"mensaje": "No se pudo enviar el correo. Intenta más tarde."}


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
    if datetime.now(timezone.utc) > usuario.reset_token_expiry:
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
    if datetime.now(timezone.utc) > usuario.reset_token_expiry:
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
# CURSOS
# =========================================================
@app.post("/cursos/", response_model=schemas.CursoResponse,
          status_code=status.HTTP_201_CREATED, tags=["Cursos"])
def crear_curso(curso: schemas.CursoCreate, db: Session = Depends(get_db)):
    nuevo = models.Curso(**curso.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/cursos/", response_model=list[schemas.CursoResponse], tags=["Cursos"])
def listar_cursos(db: Session = Depends(get_db)):
    return db.query(models.Curso).all()


# =========================================================
# USUARIOS
# Rol detectado automáticamente según dominio de email
# =========================================================
@app.post("/usuarios/", response_model=schemas.UsuarioResponse,
          status_code=status.HTTP_201_CREATED, tags=["Usuarios"])
def crear_usuario(usuario: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    if db.query(models.Usuario).filter(models.Usuario.email == usuario.email).first():
        raise HTTPException(status_code=409, detail="Ya existe un usuario con ese email.")

    usuario_data = usuario.model_dump()
    usuario_data['password_hash'] = hash_password(usuario_data['password_hash'])

    nuevo = models.Usuario(**usuario_data)
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.post("/usuarios/registro", tags=["Usuarios"])
def registrar_con_deteccion_rol(
    request: schemas.RegistroRequest,
    db: Session = Depends(get_db)
):
    if db.query(models.Usuario).filter(models.Usuario.email == request.email).first():
        raise HTTPException(status_code=409, detail="Ya existe un usuario con ese email.")

    rol_id = detectar_rol_por_email(request.email)

    if rol_id == 4 and not request.fecha_nacimiento:
        raise HTTPException(
            status_code=400,
            detail="Fecha de nacimiento es obligatoria para estudiantes."
        )
    if rol_id == 4 and not request.curso_id_curso:
        raise HTTPException(
            status_code=400,
            detail="Curso es obligatorio para estudiantes."
        )

    if request.curso_id_curso is not None:
        curso = db.query(models.Curso).filter(models.Curso.id_curso == request.curso_id_curso).first()
        if not curso:
            raise HTTPException(status_code=400, detail="El curso seleccionado no existe.")

    usuario = models.Usuario(
        rol_id_rol=rol_id,
        nombre=request.nombre,
        email=request.email,
        password_hash=hash_password(request.password),
        curso_id_curso=request.curso_id_curso,
    )
    db.add(usuario); db.commit(); db.refresh(usuario)

    resultado = {
        "id_usuario": usuario.id_usuario,
        "nombre": usuario.nombre,
        "email": usuario.email,
        "rol": db.query(models.Rol).filter(models.Rol.id_rol == rol_id).first().nombre_rol,
        "rol_id_rol": rol_id,
    }

    if rol_id == 4:
        # Crear registro en tabla estudiante
        while True:
            codigo = generar_codigo_vinculacion()
            if not db.query(models.Estudiante).filter(
                models.Estudiante.codigo_vinculacion == codigo
            ).first():
                break

        estudiante = models.Estudiante(
            nombre=request.nombre,
            fecha_nacimiento=request.fecha_nacimiento,
            curso_id_curso=request.curso_id_curso,
            codigo_vinculacion=codigo,
            usuario_id_usuario=usuario.id_usuario,
        )
        db.add(estudiante); db.commit(); db.refresh(estudiante)

        resultado["mensaje"] = "Estudiante registrado exitosamente"
        resultado["id_estudiante"] = estudiante.id_estudiante
        resultado["codigo_vinculacion"] = codigo
    else:
        resultado["mensaje"] = f"{resultado['rol']} registrado exitosamente"

    return resultado

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
# ESTUDIANTES
# =========================================================
@app.post("/estudiantes/", response_model=schemas.EstudianteResponse,
          status_code=status.HTTP_201_CREATED, tags=["Estudiantes"])
def crear_estudiante(estudiante: schemas.EstudianteCreate, db: Session = Depends(get_db)):
    if estudiante.curso_id_curso is not None:
        curso = db.query(models.Curso).filter(models.Curso.id_curso == estudiante.curso_id_curso).first()
        if not curso:
            raise HTTPException(status_code=400, detail="El curso no existe.")
    datos = estudiante.model_dump()
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

from sqlalchemy.orm import selectinload

@app.get("/estudiantes/")
def listar_estudiantes(db: Session = Depends(get_db)):

    estudiantes = db.query(models.Estudiante).options(
        selectinload(models.Estudiante.curso_r)
    ).all()

    resultado = []

    for e in estudiantes:

        # =========================
        # ESTADO (desde BD si existe, si no se calcula)
        # =========================
        if e.estado:
            estado = e.estado
        else:
            if e.puntos_totales >= 20:
                estado = "Mejorando"
            elif e.puntos_totales >= 10:
                estado = "Estable"
            else:
                estado = "Riesgo"

        # =========================
        # DIAGNÓSTICO (desde BD)
        # =========================
        diagnostico = e.diagnostico if e.diagnostico else "TEA"

        # =========================
        # SEMANA (temporal aún)
        # =========================
        semana = 0

        resultado.append({
            "id_estudiante": e.id_estudiante,
            "nombre": e.nombre,
            "puntos_totales": e.puntos_totales,

            "diagnostico": diagnostico,
            "estado": estado,
            "semana": semana,

            "curso_r": {
                "nivel_academico": e.curso_r.nivel_academico if e.curso_r else "",
                "letra_academica": e.curso_r.letra_academica if e.curso_r else ""
            } if e.curso_r else None
        })

    return resultado
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
    """Devuelve todos los estudiantes vinculados activamente a un adulto."""
    vinculos = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.usuario_id_usuario == id_usuario,
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
# VINCULACIONES
# =========================================================
@app.post("/vinculaciones/", response_model=schemas.VinculacionResponse,
          status_code=status.HTTP_201_CREATED, tags=["Vinculaciones"])
def crear_vinculacion(v: schemas.VinculacionCreate, db: Session = Depends(get_db)):
    usu = db.query(models.Usuario).filter(models.Usuario.id_usuario == v.usuario_id_usuario).first()
    if not usu:
        raise HTTPException(status_code=400, detail="El usuario no existe.")
    est = db.query(models.Estudiante).filter(models.Estudiante.id_estudiante == v.id_estudiante).first()
    if not est:
        raise HTTPException(status_code=400, detail="El estudiante no existe.")
    rol = db.query(models.Rol).filter(models.Rol.id_rol == v.rol_id_rol).first()
    if not rol:
        raise HTTPException(status_code=400, detail="El rol no existe.")
    existente = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.usuario_id_usuario == v.usuario_id_usuario,
        models.VinculacionHistorial.id_estudiante      == v.id_estudiante,
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
def vincular_por_codigo(codigo: str, id_usuario: int, rol_id_rol: int = 3, db: Session = Depends(get_db)):
    if not codigo or len(codigo) != 7 or not re.match(r'^[A-Z0-9]+$', codigo.upper()):
        raise HTTPException(status_code=400, detail="Código de vinculación inválido. Debe tener 7 caracteres alfanuméricos.")
    usu = db.query(models.Usuario).filter(models.Usuario.id_usuario == id_usuario).first()
    if not usu:
        raise HTTPException(status_code=400, detail="El usuario no existe.")
    rol = db.query(models.Rol).filter(models.Rol.id_rol == rol_id_rol).first()
    if not rol:
        raise HTTPException(status_code=400, detail="El rol no existe.")
    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.codigo_vinculacion == codigo.upper()
    ).first()
    if not estudiante:
        raise HTTPException(status_code=404, detail="Código de vinculación inválido.")
    existente = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.usuario_id_usuario == id_usuario,
        models.VinculacionHistorial.id_estudiante      == estudiante.id_estudiante,
        models.VinculacionHistorial.fecha_termino == None
    ).first()
    if existente:
        raise HTTPException(status_code=409, detail="Ya estás vinculado a este estudiante.")
    nuevo = models.VinculacionHistorial(
        usuario_id_usuario = id_usuario,
        id_estudiante      = estudiante.id_estudiante,
        rol_id_rol         = rol_id_rol,
    )
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/vinculaciones/usuario/{id_usuario}",
         response_model=list[schemas.VinculacionResponse], tags=["Vinculaciones"])
def listar_vinculaciones(id_usuario: int, db: Session = Depends(get_db)):
    return db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.usuario_id_usuario == id_usuario
    ).all()

@app.patch("/vinculaciones/{id_vinculo}/desvincular",
           response_model=schemas.VinculacionResponse, tags=["Vinculaciones"])
def desvincular(
    id_vinculo: int,
    id_usuario: int,
    motivo: str = "Desvinculación manual",
    db: Session = Depends(get_db)
):
    v = db.query(models.VinculacionHistorial).filter(
        models.VinculacionHistorial.id_vinculo == id_vinculo
    ).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vínculo no encontrado.")
    if v.usuario_id_usuario != id_usuario:
        raise HTTPException(status_code=403, detail="No tienes permiso para desvincular este estudiante.")
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
@app.post("/catalogo/", response_model=schemas.CatalogoResponse,
          status_code=status.HTTP_201_CREATED, tags=["Catálogo"])
def crear_catalogo(catalogo: schemas.CatalogoCreate, db: Session = Depends(get_db)):
    if catalogo.pictograma_id_pictograma is not None:
        picto = db.query(models.Pictograma).filter(models.Pictograma.id_pictograma == catalogo.pictograma_id_pictograma).first()
        if not picto:
            raise HTTPException(status_code=400, detail="El pictograma no existe.")
    nuevo = models.CatalogoActividad(**catalogo.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/catalogo/", response_model=list[schemas.CatalogoResponse], tags=["Catálogo"])
def listar_catalogo(db: Session = Depends(get_db)):
    return db.query(models.CatalogoActividad).all()


# =========================================================
# ACTIVIDADES
# =========================================================
@app.post("/actividades/", response_model=schemas.ActividadResponse,
          status_code=status.HTTP_201_CREATED, tags=["Actividades"])
def crear_actividad(actividad: schemas.ActividadCreate, db: Session = Depends(get_db)):
    datos = actividad.model_dump()
    alerta_minutos = datos.pop('alerta_minutos', None)

    hoy = datetime.now(CHILE_TZ).date()
    if str(actividad.fecha_actividad) < str(hoy):
        raise HTTPException(status_code=400, detail="No se pueden crear actividades en fechas pasadas.")
    ahora = datetime.now(CHILE_TZ).time()
    if actividad.fecha_actividad == hoy and actividad.hora_inicio < ahora:
        raise HTTPException(status_code=400, detail="No se pueden crear actividades con hora en el pasado.")

    est = db.query(models.Estudiante).filter(models.Estudiante.id_estudiante == datos['estudiante_id_estudiante']).first()
    if not est:
        raise HTTPException(status_code=400, detail="El estudiante seleccionado no existe.")
    usu = db.query(models.Usuario).filter(models.Usuario.id_usuario == datos['usuario_id_usuario']).first()
    if not usu:
        raise HTTPException(status_code=400, detail="El usuario seleccionado no existe.")

    if datos.get('pictograma_id_pictograma') is not None:
        picto = db.query(models.Pictograma).filter(
            models.Pictograma.id_pictograma == datos['pictograma_id_pictograma']
        ).first()
        if not picto:
            raise HTTPException(status_code=400, detail="El pictograma seleccionado no existe.")

    if datos.get('catalogo_actividad_id_catalogo') is not None:
        catalogo = db.query(models.CatalogoActividad).filter(
            models.CatalogoActividad.id_catalogo == datos['catalogo_actividad_id_catalogo']
        ).first()
        if not catalogo:
            raise HTTPException(status_code=400, detail="El catálogo de actividad no existe.")

    nueva = models.Actividad(**datos)
    db.add(nueva); db.commit(); db.refresh(nueva)
    if alerta_minutos:
        try:
            mins = int(alerta_minutos)
            if mins < 0 or mins > 480:
                raise HTTPException(status_code=400, detail="Los minutos de alerta deben estar entre 0 y 480.")
            if mins > 0:
                db.add(models.ConfiguracionAlerta(
                    actividad_id_actividad=nueva.id_actividad,
                    minutos_anticipacion=str(mins),
                ))
                db.commit()
        except (ValueError, TypeError):
            pass
    return nueva

@app.get("/actividades/estudiante/{id_estudiante}",
         response_model=list[schemas.ActividadResponse], tags=["Actividades"])
def listar_actividades_estudiante(
    id_estudiante: int,
    fecha: date | None = Query(None, description="Filtrar por fecha (YYYY-MM-DD)"),
    db: Session = Depends(get_db)
):
    q = db.query(models.Actividad).filter(
        models.Actividad.estudiante_id_estudiante == id_estudiante
    ).options(selectinload(models.Actividad.creador).selectinload(models.Usuario.rol))
    if fecha:
        q = q.filter(models.Actividad.fecha_actividad == fecha)
    actividades = q.order_by(models.Actividad.hora_inicio.asc()).all()
    resultado = []
    for a in actividades:
        item = {
            "id_actividad": a.id_actividad,
            "estudiante_id_estudiante": a.estudiante_id_estudiante,
            "usuario_id_usuario": a.usuario_id_usuario,
            "pictograma_id_pictograma": a.pictograma_id_pictograma,
            "catalogo_actividad_id_catalogo": a.catalogo_actividad_id_catalogo,
            "nombre_tarea": a.nombre_tarea,
            "hora_inicio": a.hora_inicio,
            "hora_fin": a.hora_fin,
            "es_completada": a.es_completada,
            "fecha_actividad": a.fecha_actividad,
            "fecha_creacion": a.fecha_creacion,
            "usuario_rol": a.creador.rol.nombre_rol if a.creador and a.creador.rol else None,
        }
        resultado.append(schemas.ActividadResponse(**item))
    return resultado

@app.patch("/actividades/{id_actividad}/completar",
           response_model=schemas.ActividadResponse, tags=["Actividades"])
def completar_actividad(id_actividad: int, db: Session = Depends(get_db)):
    a = db.query(models.Actividad).filter(
        models.Actividad.id_actividad == id_actividad
    ).first()
    if not a:
        raise HTTPException(status_code=404, detail="Actividad no encontrada.")

    estaba_completada = a.es_completada
    a.es_completada = not a.es_completada
    hoy = datetime.now(CHILE_TZ).date()

    if a.fecha_actividad < hoy:
    raise HTTPException(
        status_code=400,
        detail="No se pueden completar actividades de días pasados."
    )

    if not estaba_completada:
        # Completando: +1 estrella, +1 punto, registrar historial
        registro = db.query(models.RegistroEstrellaDiaria).filter(
            models.RegistroEstrellaDiaria.estudiante_id_estudiante == a.estudiante_id_estudiante,
            models.RegistroEstrellaDiaria.fecha == a.fecha_actividad,
        ).first()
        if registro:
            registro.estrellas_ganadas += 1
        else:
            db.add(models.RegistroEstrellaDiaria(
                estudiante_id_estudiante=a.estudiante_id_estudiante,
                fecha=a.fecha_actividad,
                estrellas_ganadas=1,
            ))

        db.add(models.HistorialCumplimiento(
            actividad_id_actividad=a.id_actividad,
            observaciones="Actividad completada",
        ))

        est = db.query(models.Estudiante).filter(
            models.Estudiante.id_estudiante == a.estudiante_id_estudiante
        ).first()
        if est:
            est.puntos_totales += 1
    else:
        # Desmarcando: -1 estrella, -1 punto (mínimo 0)
        registro = db.query(models.RegistroEstrellaDiaria).filter(
            models.RegistroEstrellaDiaria.estudiante_id_estudiante == a.estudiante_id_estudiante,
            models.RegistroEstrellaDiaria.fecha == a.fecha_actividad,
        ).first()
        if registro and registro.estrellas_ganadas > 0:
            registro.estrellas_ganadas -= 1

        est = db.query(models.Estudiante).filter(
            models.Estudiante.id_estudiante == a.estudiante_id_estudiante
        ).first()
        if est and est.puntos_totales > 0:
            est.puntos_totales -= 1

    db.commit(); db.refresh(a)
    return a

@app.patch("/actividades/{id_actividad}",
           response_model=schemas.ActividadResponse, tags=["Actividades"])
def actualizar_actividad(id_actividad: int, datos: schemas.ActividadUpdate, db: Session = Depends(get_db)):
    a = db.query(models.Actividad).filter(
        models.Actividad.id_actividad == id_actividad
    ).first()
    if not a:
        raise HTTPException(status_code=404, detail="Actividad no encontrada.")

    datos_dict = datos.model_dump(exclude_unset=True)

    nueva_fecha = datos_dict.get('fecha_actividad', a.fecha_actividad)
    nueva_inicio = datos_dict.get('hora_inicio', a.hora_inicio)

    hoy = datetime.now(CHILE_TZ).date()
    if nueva_fecha < hoy:
        raise HTTPException(status_code=400, detail="No se pueden mover actividades a fechas pasadas.")
    ahora = datetime.now(CHILE_TZ).time()
    if nueva_fecha == hoy and nueva_inicio is not None and nueva_inicio < ahora:
        raise HTTPException(status_code=400, detail="No se pueden asignar horas en el pasado.")

    est_id = datos_dict.get('estudiante_id_estudiante')
    if est_id is not None:
        est = db.query(models.Estudiante).filter(models.Estudiante.id_estudiante == est_id).first()
        if not est:
            raise HTTPException(status_code=400, detail="El estudiante seleccionado no existe.")

    picto_id = datos_dict.get('pictograma_id_pictograma')
    if picto_id is not None:
        picto = db.query(models.Pictograma).filter(models.Pictograma.id_pictograma == picto_id).first()
        if not picto:
            raise HTTPException(status_code=400, detail="El pictograma seleccionado no existe.")

    catalogo_id = datos_dict.get('catalogo_actividad_id_catalogo')
    if catalogo_id is not None:
        catalogo = db.query(models.CatalogoActividad).filter(models.CatalogoActividad.id_catalogo == catalogo_id).first()
        if not catalogo:
            raise HTTPException(status_code=400, detail="El catálogo de actividad no existe.")

    nueva_inicio = datos_dict.get('hora_inicio', a.hora_inicio)
    nueva_fin = datos_dict.get('hora_fin', a.hora_fin)
    if nueva_inicio is not None and nueva_fin is not None and nueva_fin <= nueva_inicio:
        raise HTTPException(status_code=400, detail="La hora de fin debe ser mayor que la hora de inicio.")

    for campo, valor in datos_dict.items():
        setattr(a, campo, valor)
    db.commit(); db.refresh(a)
    return a

@app.delete("/actividades/{id_actividad}", tags=["Actividades"])
def eliminar_actividad(id_actividad: int, db: Session = Depends(get_db)):
    a = db.query(models.Actividad).filter(
        models.Actividad.id_actividad == id_actividad
    ).first()
    if not a:
        raise HTTPException(status_code=404, detail="Actividad no encontrada.")
    db.delete(a); db.commit()
    return {"mensaje": "Actividad eliminada exitosamente"}


# =========================================================
# HISTORIAL DE CUMPLIMIENTO
# =========================================================
@app.post("/historial/", response_model=schemas.HistorialResponse,
          status_code=status.HTTP_201_CREATED, tags=["Historial"])
def registrar_cumplimiento(historial: schemas.HistorialCreate, db: Session = Depends(get_db)):
    act = db.query(models.Actividad).filter(models.Actividad.id_actividad == historial.actividad_id_actividad).first()
    if not act:
        raise HTTPException(status_code=400, detail="La actividad no existe.")
    nuevo = models.HistorialCumplimiento(**historial.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/historial/estudiante/{id_estudiante}",
         response_model=list[schemas.HistorialResponse], tags=["Historial"])
def historial_estudiante(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.HistorialCumplimiento).join(models.Actividad).filter(
        models.Actividad.estudiante_id_estudiante == id_estudiante
    ).all()


# =========================================================
# RECOMPENSAS
# =========================================================
@app.post("/recompensas/", response_model=schemas.RecompensaResponse,
          status_code=status.HTTP_201_CREATED, tags=["Recompensas"])
def crear_recompensa(recompensa: schemas.RecompensaCreate, db: Session = Depends(get_db)):
    est = db.query(models.Estudiante).filter(models.Estudiante.id_estudiante == recompensa.estudiante_id_estudiante).first()
    if not est:
        raise HTTPException(status_code=400, detail="El estudiante no existe.")
    nueva = models.RecompensaDisponible(**recompensa.model_dump())
    db.add(nueva); db.commit(); db.refresh(nueva)
    return nueva

@app.get("/recompensas/estudiante/{id_estudiante}",
         response_model=list[schemas.RecompensaResponse], tags=["Recompensas"])
def listar_recompensas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RecompensaDisponible).filter(
        models.RecompensaDisponible.estudiante_id_estudiante == id_estudiante
    ).all()


# =========================================================
# ESTRELLAS DIARIAS
# =========================================================
@app.post("/estrellas/", response_model=schemas.EstrellaResponse,
          status_code=status.HTTP_201_CREATED, tags=["Estrellas"])
def registrar_estrellas(estrella: schemas.EstrellaCreate, db: Session = Depends(get_db)):
    est = db.query(models.Estudiante).filter(models.Estudiante.id_estudiante == estrella.estudiante_id_estudiante).first()
    if not est:
        raise HTTPException(status_code=400, detail="El estudiante no existe.")
    nuevo = models.RegistroEstrellaDiaria(**estrella.model_dump())
    db.add(nuevo); db.commit(); db.refresh(nuevo)
    return nuevo

@app.get("/estrellas/estudiante/{id_estudiante}",
         response_model=list[schemas.EstrellaResponse], tags=["Estrellas"])
def listar_estrellas(id_estudiante: int, db: Session = Depends(get_db)):
    return db.query(models.RegistroEstrellaDiaria).filter(
        models.RegistroEstrellaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()


from fastapi.staticfiles import StaticFiles
app.mount(
    "/panel",
    StaticFiles(directory="static/admin", html=True),
    name="panel"
)

app.include_router(admin_router, prefix="/admin", tags=["Admin"])

from collections import Counter

# =========================================================
# ENCUESTA DIARIA APODERADO
# =========================================================

@app.post(
    "/encuestas/",
    response_model=schemas.EncuestaDiariaResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Encuestas"]
)
def crear_encuesta(
    encuesta: schemas.EncuestaDiariaCreate,
    db: Session = Depends(get_db)
):

    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == encuesta.estudiante_id_estudiante
    ).first()

    if not estudiante:
        raise HTTPException(
            status_code=404,
            detail="Estudiante no encontrado"
        )

    hoy = date.today()

    encuesta_existente = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == encuesta.estudiante_id_estudiante,
        models.EncuestaDiaria.fecha == hoy
    ).first()

    if encuesta_existente:
        raise HTTPException(
            status_code=400,
            detail="Ya existe una encuesta registrada para hoy."
        )

    nueva = models.EncuestaDiaria(**encuesta.model_dump())

    db.add(nueva)
    db.commit()
    db.refresh(nueva)

    return nueva


@app.get(
    "/encuestas/estudiante/{id_estudiante}",
    response_model=list[schemas.EncuestaDiariaResponse],
    tags=["Encuestas"]
)
def obtener_encuestas_estudiante(
    id_estudiante: int,
    db: Session = Depends(get_db)
):

    return db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante
    ).order_by(
        models.EncuestaDiaria.fecha.desc()
    ).all()


@app.get(
    "/encuestas/verificar/{id_estudiante}",
    tags=["Encuestas"]
)
def verificar_encuesta_hoy(
    id_estudiante: int,
    db: Session = Depends(get_db)
):

    hoy = date.today()

    encuesta = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante,
        models.EncuestaDiaria.fecha == hoy
    ).first()

    return {
        "respondida": encuesta is not None
    }


@app.get(
    "/encuestas/resumen/{id_estudiante}",
    tags=["Encuestas"]
)
def resumen_desregulaciones(
    id_estudiante: int,
    db: Session = Depends(get_db)
):

    encuestas = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()

    total_encuestas = len(encuestas)

    total_desregulaciones = sum(
        e.cantidad or 0
        for e in encuestas
        if e.tuvo_desregulacion
    )

    dias_con_desregulacion = sum(
        1
        for e in encuestas
        if e.tuvo_desregulacion
    )

    return {
        "total_encuestas": total_encuestas,
        "dias_con_desregulacion": dias_con_desregulacion,
        "total_desregulaciones": total_desregulaciones
    }


@app.get(
    "/encuestas/motivos/{id_estudiante}",
    tags=["Encuestas"]
)
def motivos_frecuentes(
    id_estudiante: int,
    db: Session = Depends(get_db)
):

    encuestas = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante,
        models.EncuestaDiaria.tuvo_desregulacion == True
    ).all()

    motivos = [
        e.motivo
        for e in encuestas
        if e.motivo
    ]

    contador = Counter(motivos)

    return contador.most_common()


# =========================================================
# REPORTE ESTUDIANTE
# =========================================================

@app.get("/reportes/estudiante/{id_estudiante}")
def reporte_estudiante(
    id_estudiante: int,
    db: Session = Depends(get_db)
):

    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == id_estudiante
    ).first()

    if not estudiante:
        raise HTTPException(
            status_code=404,
            detail="Estudiante no encontrado"
        )

    actividades = db.query(models.Actividad).filter(
        models.Actividad.estudiante_id_estudiante == id_estudiante
    ).all()

    estrellas = db.query(models.RegistroEstrellaDiaria).filter(
        models.RegistroEstrellaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()

    encuestas = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()

    recompensas = db.query(models.RecompensaDisponible).filter(
        models.RecompensaDisponible.estudiante_id_estudiante == id_estudiante
    ).all()

    total_actividades = len(actividades)

    completadas = len([
        a for a in actividades
        if a.es_completada
    ])

    total_estrellas = sum(
        e.estrellas_ganadas
        for e in estrellas
    )

    total_desregulaciones = sum(
        e.cantidad or 0
        for e in encuestas
        if e.tuvo_desregulacion
    )

    return {
        "estudiante": estudiante.nombre,
        "curso": estudiante.curso_r.nivel_academico if estudiante.curso_r else "",
        "puntos_totales": estudiante.puntos_totales,
        "actividades_totales": total_actividades,
        "actividades_completadas": completadas,
        "estrellas": total_estrellas,
        "desregulaciones": total_desregulaciones,
        "recompensas": len(recompensas)
    }


# =========================================================
# DASHBOARD REPORTES ADMIN
# =========================================================

@app.get("/reportes/dashboard")
def dashboard_reportes(db: Session = Depends(get_db)):

    estudiantes = db.query(models.Estudiante).all()
    encuestas = db.query(models.EncuestaDiaria).all()

    total_estudiantes = len(estudiantes)
    total_desregulaciones = sum(e.cantidad or 0 for e in encuestas if e.tuvo_desregulacion)

    motivos = Counter(e.motivo for e in encuestas if e.motivo)

    motivo_principal = motivos.most_common(1)[0][0] if motivos else "Sin datos"

    return {
        "mejoraGlobal": "37%",  # luego lo puedes calcular real
        "riesgoAlto": 4,
        "factorPrincipal": motivo_principal,
        "cursoCritico": "5°A",

        "evolucion": {
            "labels": ["Ene","Feb","Mar","Abr","May","Jun"],
            "data": [120,110,98,85,72,64]
        },

        "factores": {
            "labels": list(motivos.keys())[:5],
            "data": list(motivos.values())[:5]
        },

        "dias": {
            "labels": ["Lun","Mar","Mié","Jue","Vie"],
            "data": [25,30,18,35,14]
        },

        "cursos": {
            "labels": ["1°A","2°A","3°A","4°A","5°A"],
            "data": [8,12,18,10,25]
        },

        "hallazgos": [
            "Las desregulaciones están concentradas en ciertos días.",
            "El factor principal es el más recurrente.",
            "El sistema permite detección temprana de crisis."
        ]
    }

@app.get("/reportes/pdf/{id_estudiante}")
def descargar_reporte_pdf(id_estudiante: int, db: Session = Depends(get_db)):

    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == id_estudiante
    ).first()

    if not estudiante:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado")

    actividades = db.query(models.Actividad).filter(
        models.Actividad.estudiante_id_estudiante == id_estudiante
    ).all()

    estrellas = db.query(models.RegistroEstrellaDiaria).filter(
        models.RegistroEstrellaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()

    encuestas = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id_estudiante
    ).all()

    total_actividades = len(actividades)
    completadas = sum(1 for a in actividades if a.es_completada)
    total_estrellas = sum(e.estrellas_ganadas for e in estrellas)
    total_desregulaciones = sum(e.cantidad or 0 for e in encuestas if e.tuvo_desregulacion)

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer)
    styles = getSampleStyleSheet()

    content = []

    content.append(Paragraph("REPORTE ESTUDIANTE", styles["Title"]))
    content.append(Spacer(1, 12))

    data = [
        ["Campo", "Valor"],
        ["Nombre", estudiante.nombre],
        ["Curso", estudiante.curso_r.nivel_academico + estudiante.curso_r.letra_academica if estudiante.curso_r else ""],
        ["Puntos Totales", str(estudiante.puntos_totales)],
        ["Actividades Totales", str(total_actividades)],
        ["Actividades Completadas", str(completadas)],
        ["Estrellas Ganadas", str(total_estrellas)],
        ["Desregulaciones", str(total_desregulaciones)],
    ]

    table = Table(data, colWidths=[200, 300])

    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1F4E79")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ALIGN", (0, 0), (-1, -1), "LEFT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))

    content.append(table)

    doc.build(content)

    buffer.seek(0)

    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={"Content-Disposition": f"inline; filename=reporte_{id_estudiante}.pdf"}
    )

def descargar_reporte_pdf(...):
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer)
    estilos = getSampleStyleSheet()
    contenido = []

    contenido.append(
        Paragraph(
            "Reporte Anticipa",
            estilos["Title"]
        )
    )

    contenido.append(Spacer(1,12))

    contenido.append(
        Paragraph(
            f"Estudiante: {estudiante.nombre}",
            estilos["Normal"]
        )
    )

    contenido.append(
        Paragraph(
            f"Puntos Totales: {estudiante.puntos_totales}",
            estilos["Normal"]
        )
    )

    contenido.append(
        Paragraph(
            f"Actividades Totales: {total_actividades}",
            estilos["Normal"]
        )
    )

    contenido.append(
        Paragraph(
            f"Actividades Completadas: {completadas}",
            estilos["Normal"]
        )
    )

    contenido.append(
        Paragraph(
            f"Estrellas Ganadas: {total_estrellas}",
            estilos["Normal"]
        )
    )

    contenido.append(
        Paragraph(
            f"Desregulaciones Detectadas: {total_desregulaciones}",
            estilos["Normal"]
        )
    )

    doc.build(contenido)

buffer.seek(0)

return StreamingResponse(
    buffer,
    media_type="application/pdf",
    headers={
        "Content-Disposition": f"inline; filename=reporte_{id_estudiante}.pdf"
    }
)

@app.get("/reportes/detalle-estudiante/{id}")
def detalle_estudiante(id: int, db: Session = Depends(get_db)):

    estudiante = db.query(models.Estudiante).filter(
        models.Estudiante.id_estudiante == id
    ).first()

    if not estudiante:
        raise HTTPException(
            status_code=404,
            detail="Estudiante no encontrado"
        )

    hoy = date.today()

    # Desregulaciones hoy
    encuesta_hoy = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id,
        models.EncuestaDiaria.fecha == hoy
    ).first()

    dato_hoy = (
        encuesta_hoy.cantidad
        if encuesta_hoy and encuesta_hoy.tuvo_desregulacion
        else 0
    )

    # Últimos 7 días
    semana_inicio = hoy - timedelta(days=7)

    encuestas_semana = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id,
        models.EncuestaDiaria.fecha >= semana_inicio
    ).all()

    dato_semana = sum(
        e.cantidad or 0
        for e in encuestas_semana
        if e.tuvo_desregulacion
    )

    # Últimos 30 días
    mes_inicio = hoy - timedelta(days=30)

    encuestas_mes = db.query(models.EncuestaDiaria).filter(
        models.EncuestaDiaria.estudiante_id_estudiante == id,
        models.EncuestaDiaria.fecha >= mes_inicio
    ).all()

    dato_mes = sum(
        e.cantidad or 0
        for e in encuestas_mes
        if e.tuvo_desregulacion
    )

    # Evolución mensual
    historial = []

    for i in range(5, -1, -1):

        inicio_mes = date(
            hoy.year,
            hoy.month,
            1
        ) - timedelta(days=i * 30)

        fin_mes = inicio_mes + timedelta(days=30)

        total = sum(
            e.cantidad or 0
            for e in db.query(models.EncuestaDiaria).filter(
                models.EncuestaDiaria.estudiante_id_estudiante == id,
                models.EncuestaDiaria.fecha >= inicio_mes,
                models.EncuestaDiaria.fecha < fin_mes
            ).all()
            if e.tuvo_desregulacion
        )

        historial.append(total)

    return {
        "nombre": estudiante.nombre,
        "curso": (
            f"{estudiante.curso_r.nivel_academico}{estudiante.curso_r.letra_academica}"
            if estudiante.curso_r
            else ""
        ),
        "hoy": dato_hoy,
        "semana": dato_semana,
        "mes": dato_mes,
        "historial": historial
    }


@app.get("/reportes/pdf-general")
def reporte_general_pdf(db: Session = Depends(get_db)):

    estudiantes = db.query(models.Estudiante).all()
    encuestas = db.query(models.EncuestaDiaria).all()

    total_estudiantes = len(estudiantes)

    total_desregulaciones = sum(
        e.cantidad or 0 for e in encuestas if e.tuvo_desregulacion
    )

    motivos = Counter(
        e.motivo for e in encuestas if e.motivo
    )

    motivo_principal = motivos.most_common(1)[0][0] if motivos else "Sin datos"

    buffer = io.BytesIO()
    doc = SimpleDocTemplate(buffer)
    estilos = getSampleStyleSheet()
    contenido = []

    contenido.append(Paragraph("REPORTE GENERAL ESCUELA", estilos["Title"]))
    contenido.append(Spacer(1, 12))

    contenido.append(Paragraph(f"Total estudiantes: {total_estudiantes}", estilos["Normal"]))
    contenido.append(Paragraph(f"Total desregulaciones: {total_desregulaciones}", estilos["Normal"]))
    contenido.append(Paragraph(f"Motivo principal: {motivo_principal}", estilos["Normal"]))

    doc.build(contenido)
    buffer.seek(0)

    return StreamingResponse(
        buffer,
        media_type="application/pdf",
        headers={
            "Content-Disposition": "inline; filename=reporte_general.pdf"
        }
    )


