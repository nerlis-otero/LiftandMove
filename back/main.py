from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from uuid import uuid4
from pydantic import BaseModel, EmailStr
from jose import jwt, JWTError

import pymysql
import pymysql.cursors
import bcrypt

from datetime import datetime, timedelta, timezone
from typing import Any
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")

DB_HOST = os.getenv("DB_HOST")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# Fallbacks para no romper si falta .env
if SECRET_KEY is None:
    raise RuntimeError("SECRET_KEY no configurado en .env")


if DB_HOST is None:
    raise RuntimeError("DB_HOST no configurado en .env")
if DB_USER is None:
    raise RuntimeError("DB_USER no configurado en .env")
if DB_PASSWORD is None:
    raise RuntimeError("DB_PASSWORD no configurado en .env")
if DB_NAME is None:
    raise RuntimeError("DB_NAME no configurado en .env")





ALGORITHM = "HS256"
TOKEN_EXPIRA_EN_MINUTOS = 60

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_db_connection():
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor
    )


# get_db_connection() definido arriba con variables de entorno


class UserDataRegister(BaseModel):
    idUsu: str
    nombreUsu: str
    correoUsu: EmailStr
    contrasenha: str
    sexo: str
    altura_cm: int
    peso: int
    objetivo_entreno: str

class UserDataLogin(BaseModel):
    nombreUsu: str
    contrasenha: str

class UsuarioActual(BaseModel):
    idUsu: str
    nombreUsu: str
    correoUsu: str
    esAdmin: bool = False

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(
        plain_password.encode('utf-8'),
        hashed_password.encode('utf-8')
    )

def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(
        password.encode('utf-8'),
        bcrypt.gensalt()
    ).decode('utf-8')

def crear_token_acceso(datos: dict) -> str:
    payload = datos.copy()
    expiracion = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_EXPIRA_EN_MINUTOS)
    payload.update({"exp": expiracion})
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token

def get_usuario_actual(token: str = Depends(oauth2_scheme)) -> UsuarioActual:

    error_credenciales = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciales invalidas o token expirado",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        id_usu: str = payload.get("sub")
        if id_usu is None:
            raise error_credenciales
    except JWTError:
        raise error_credenciales

    
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT idUsu, nombreUsu, correoUsu, esAdmin FROM usuarios WHERE idUsu = %s",
                (id_usu,)
            )
            fila = cursor.fetchone()
    finally:
        connection.close()

    if fila is None:
        raise error_credenciales

    return UsuarioActual(**fila)

app = FastAPI(title="LiftMove API", version="1.0.0") 
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "API funcionando correctamente"}


@app.get("/me", response_model=UsuarioActual)
def quien_soy(usuario: UsuarioActual = Depends(get_usuario_actual)):

    return usuario

@app.post("/register")
def register(data: UserDataRegister) -> Any:
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM usuarios WHERE idUsu = %s", (data.idUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El id del usuario ya existe")

            cursor.execute("SELECT * FROM usuarios WHERE nombreUsu = %s", (data.nombreUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El nombre de usuario ya existe")

            cursor.execute("SELECT * FROM usuarios WHERE correoUsu = %s", (data.correoUsu,))
            if cursor.fetchone():
                raise HTTPException(status_code=400, detail="El correo ya está registrado")

            if data.sexo not in ["M", "F"]:
                raise HTTPException(status_code=400, detail="El sexo debe ser 'M' o 'F'")

            
            hashed_password = get_password_hash(data.contrasenha)

            sql = """
                INSERT INTO usuarios
                (idUsu, nombreUsu, correoUsu, contrasenha, sexo, altura_cm, peso, objetivo_entreno)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                data.idUsu,
                data.nombreUsu,
                data.correoUsu,
                hashed_password,
                data.sexo,
                data.altura_cm,
                data.peso,
                data.objetivo_entreno
            ))
            connection.commit()

            return {"success": True, "message": "Usuario creado exitosamente"}
    finally:
        connection.close()

@app.post("/login")
def login(data: UserDataLogin) -> Any:
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM usuarios WHERE nombreUsu = %s",
                (data.nombreUsu,)
            )
            user = cursor.fetchone()

            
            if not user or not verify_password(data.contrasenha, user['contrasenha']):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Credenciales incorrectas"
                )

            
            token = crear_token_acceso({
                "sub": user["idUsu"],
                "nombreUsu": user["nombreUsu"],
                "esAdmin": bool(user["esAdmin"])
            })

            return {
                "success": True,
                "message": "Autenticacion exitosa",
                "access_token": token,
                "token_type": "bearer",
                "nombreUsu": user["nombreUsu"],
                "esAdmin": bool(user["esAdmin"])
            }
    finally:
        connection.close()
        
def get_admin_usuario(usuario: UsuarioActual = Depends(get_usuario_actual)):
    if not usuario.esAdmin:
        raise HTTPException(status_code=403, detail="Acceso denegado")
    return usuario

@app.get("/admin/usuarios")
def admin_listar_usuarios(admin: UsuarioActual = Depends(get_admin_usuario)):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT idUsu, nombreUsu, correoUsu, sexo, peso, altura_cm, objetivo_entreno, esAdmin FROM usuarios")
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/check-usuario/{nombreUsu}")
def check_usuario(nombreUsu: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT 1 FROM usuarios WHERE nombreUsu = %s LIMIT 1",
                (nombreUsu,),
            )
            if cursor.fetchone():
                raise HTTPException(status_code=409, detail="Usuario existente")
            return {"disponible": True}
    finally:
        connection.close()


@app.delete("/admin/usuarios/{idUsu}")
def admin_eliminar_usuario(idUsu: str, admin: UsuarioActual = Depends(get_admin_usuario)):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM usuarios WHERE idUsu = %s", (idUsu,))
            connection.commit()
            return {"success": True, "message": "Usuario eliminado exitosamente"}
    finally:
        connection.close()

# ─── EJERCICIOS ───────────────────────────────────────────

@app.get("/ejercicios")
def get_ejercicios(
    skip: int = 0,
    limit: int = 20,
    categoria: str = None,
    equipamiento: str = None,
    nivel: str = None
):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            query = "SELECT idEjercicio, nombreEj, tipo, equipamiento, nivel FROM ejercicios WHERE 1=1"
            params = []
            if categoria:
                query += " AND tipo = %s"
                params.append(categoria)
            if equipamiento:
                query += " AND equipamiento = %s"
                params.append(equipamiento)
            if nivel:
                query += " AND nivel = %s"
                params.append(nivel)
            query += " LIMIT %s OFFSET %s"
            params.extend([limit, skip])
            cursor.execute(query, params)
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/buscar")
def buscar_ejercicios(q: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT idEjercicio, nombreEj, tipo, equipamiento, nivel FROM ejercicios WHERE nombreEj LIKE %s LIMIT 20",
                (f"%{q}%",)
            )
            return cursor.fetchall()
    finally:
        connection.close()

@app.get("/ejercicios/{ejercicio_id}")
def get_ejercicio(ejercicio_id: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT * FROM ejercicios WHERE idEjercicio = %s",
                (ejercicio_id,)
            )
            ej = cursor.fetchone()
            if not ej:
                raise HTTPException(status_code=404, detail="Ejercicio no encontrado")

            # Traer músculos
            cursor.execute("""
                SELECT m.nombreMusc, em.rol
                FROM ejercicio_musculo em
                JOIN musculos m ON em.idMusculo = m.idMusculo
                WHERE em.idEjercicio = %s
            """, (ejercicio_id,))
            musculos = cursor.fetchall()
            ej["musculos"] = musculos
            return ej
    finally:
        connection.close()

@app.get("/categorias")
def get_categorias():
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT DISTINCT tipo FROM ejercicios WHERE tipo IS NOT NULL ORDER BY tipo")
            rows = cursor.fetchall()
            return [r["tipo"] for r in rows]
    finally:
        connection.close()

@app.get("/musculos")
def get_musculos():
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM musculos ORDER BY nombreMusc")
            return cursor.fetchall()
    finally:
        connection.close()
# ─── AGREGAR AL FINAL DE main.py ───────────────────────────────────────────
# Asegúrate de tener: from uuid import uuid4  (ya debe estar arriba)

from pydantic import BaseModel
from typing import List

# ── Modelos ──────────────────────────────────────────────────────────────────

class EjercicioPlantilla(BaseModel):
    idEjercicio: str
    series: int
    repeticiones: int
    peso_kg: float | None = None

# Compatibilidad con Flutter: algunos clientes pueden enviar "peso" en lugar de "peso_kg"
# (o enviar ambos). En el endpoint se normaliza.


class GuardarPlantillaRequest(BaseModel):
    idUsu: str
    nombre: str
    fecha_inicio: str        # "2025-05-18"
    fecha_fin: str           # "2025-06-18"
    dias_semana: List[int]   # [0,1] = Lunes y Martes (0=Lun...6=Dom)
    ejercicios: List[EjercicioPlantilla]

# ── Guardar plantilla de rutina ───────────────────────────────────────────────

@app.post("/rutinas")
def guardar_rutina(data: GuardarPlantillaRequest):
    if not data.dias_semana:
        raise HTTPException(status_code=400, detail="Debes seleccionar al menos un día")
    if not data.ejercicios:
        raise HTTPException(status_code=400, detail="Debes agregar al menos un ejercicio")

    # Normaliza la carga recibida para compatibilidad con Flutter
    # (clientes pueden mandar "peso" en lugar de "peso_kg" o ambos).
    for ej in data.ejercicios:
        if ej.peso_kg is None:
            ej.peso_kg = 0.0

    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            id_plantilla = str(uuid4())

            # 1. Insertar plantilla
            cursor.execute(
                """
                INSERT INTO rutina_plantilla (idPlantilla, idUsu, nombre, fecha_inicio, fecha_fin)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (id_plantilla, data.idUsu, data.nombre, data.fecha_inicio, data.fecha_fin)
            )

            # 2. Insertar días de la semana
            for dia in data.dias_semana:
                cursor.execute(
                    "INSERT INTO rutina_dias (idPlantilla, dia_semana) VALUES (%s, %s)",
                    (id_plantilla, dia)
                )

            # 3. Insertar ejercicios
            for orden, ej in enumerate(data.ejercicios):
                cursor.execute(
                    """
                    INSERT INTO rutina_ejercicio
                        (idRutinaEj, idPlantilla, idEjercicio, series, repeticiones, peso_kg, orden)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (str(uuid4()), id_plantilla, ej.idEjercicio,
                     ej.series, ej.repeticiones, ej.peso_kg, orden + 1)
                )

            connection.commit()
            return {"success": True, "idPlantilla": id_plantilla}

    except Exception as e:
        connection.rollback()
        raise HTTPException(status_code=500, detail=f"Error al guardar: {str(e)}")
    finally:
        connection.close()

# ── Consultar rutinas de un usuario para una fecha específica ─────────────────

@app.get("/rutinas/{idUsu}")
def get_rutinas_por_fecha(idUsu: str, fecha: str):
    """
    Devuelve las rutinas que aplican para la fecha dada.
    Filtra por: fecha dentro del rango inicio-fin Y día de semana coincide.
    Ejemplo: GET /rutinas/USU001?fecha=2025-05-20
    """
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT 
                    rp.idPlantilla,
                    rp.nombre,
                    rp.fecha_inicio,
                    rp.fecha_fin,
                    COUNT(re.idRutinaEj) AS total_ejercicios
                FROM rutina_plantilla rp
                JOIN rutina_dias rd ON rp.idPlantilla = rd.idPlantilla
                LEFT JOIN rutina_ejercicio re ON rp.idPlantilla = re.idPlantilla
                WHERE rp.idUsu = %s
                  AND %s BETWEEN rp.fecha_inicio AND rp.fecha_fin
                  AND rd.dia_semana = WEEKDAY(%s)
                GROUP BY rp.idPlantilla
                ORDER BY rp.nombre
                """,
                (idUsu, fecha, fecha)
            )
            return cursor.fetchall()
    finally:
        connection.close()

# ── Detalle de una rutina (ejercicios) ────────────────────────────────────────
@app.get("/rutinas/detalle/{idPlantilla}")
def get_detalle_rutina(idPlantilla: str):
    # idPlantilla viene como string (UUID) desde Flutter.
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            sql = """
                SELECT 
                    re.idEjercicio,
                    e.nombreEj,
                    re.series,
                    re.repeticiones,
                    re.peso_kg
                FROM rutina_ejercicio re
                JOIN ejercicios e ON re.idEjercicio = e.idEjercicio
                WHERE re.idPlantilla = %s
                ORDER BY re.orden ASC
            """

            cursor.execute(sql, (idPlantilla,))
            resultados = cursor.fetchall()

            lista_ejercicios = []
            for fila in resultados:
                peso_val = fila.get("peso_kg")
                lista_ejercicios.append({
                    "idEjercicio": fila["idEjercicio"],
                    "nombreEj": fila["nombreEj"],
                    "series": fila["series"],
                    "repeticiones": fila["repeticiones"],
                    # Flutter suele consumir "peso".
                    "peso": float(peso_val) if peso_val is not None else 0.0,
                })

            return lista_ejercicios

    except Exception as e:
        print(f"Error en endpoint detalle: {e}")
        raise HTTPException(status_code=500, detail="Error interno del servidor")
    finally:
        connection.close()
# ── Eliminar rutina ───────────────────────────────────────────────────────────

@app.delete("/rutinas/{idPlantilla}")
def eliminar_rutina(idPlantilla: str):
    connection = get_db_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("DELETE FROM rutina_ejercicio WHERE idPlantilla = %s", (idPlantilla,))
            cursor.execute("DELETE FROM rutina_dias WHERE idPlantilla = %s", (idPlantilla,))
            cursor.execute("DELETE FROM rutina_plantilla WHERE idPlantilla = %s", (idPlantilla,))
            connection.commit()
            return {"success": True}
    finally:
        connection.close()