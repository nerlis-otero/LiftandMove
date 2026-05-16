import json
import pymysql

try:
    print("1. Conectando a MySQL...")
    conn = pymysql.connect(
        host="localhost",
        user="root",
        password="delfin123",
        database="rutinas_ejercicios"
    )
    print("2. Conectado!")
    cursor = conn.cursor()

    print("3. Leyendo JSON...")
    with open("exercises.json", "r", encoding="utf-8") as f:
        ejercicios = json.load(f)
    print(f"4. JSON cargado: {len(ejercicios)} ejercicios")

    musculos_insertados = set()
except Exception as e:
    print(f"❌ Error: {e}")
    raise


for e in ejercicios:
    # (paso 5) Insertando ejercicio y relaciones
    ej_id = e.get("id", "")
    nombre = e.get("name", "")[:100]
    categoria = e.get("category", "")
    equipamiento = e.get("equipment", "")
    nivel = e.get("level", "")
    instrucciones = json.dumps(e.get("instructions", []))
    imagenes = json.dumps(e.get("images", []))

    # Insertar ejercicio
    cursor.execute("""
        INSERT IGNORE INTO ejercicios 
        (idEjercicio, nombreEj, tipo, equipamiento, nivel, instrucciones, imagenes)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (ej_id, nombre, categoria, equipamiento, nivel, instrucciones, imagenes))

    # Insertar músculos y relaciones
    primary = e.get("primaryMuscles", [])
    secondary = e.get("secondaryMuscles", [])

    for musculo in primary:
        if musculo not in musculos_insertados:
            cursor.execute("""
                INSERT IGNORE INTO musculos (idMusculo, nombreMusc, grupo_muscular)
                VALUES (%s, %s, %s)
            """, (musculo, musculo, "primary"))
            musculos_insertados.add(musculo)
        cursor.execute("""
            INSERT IGNORE INTO ejercicio_musculo (idEjercicio, idMusculo, rol)
            VALUES (%s, %s, %s)
        """, (ej_id, musculo, 1))  # rol 1 = primario

    for musculo in secondary:
        if musculo not in musculos_insertados:
            cursor.execute("""
                INSERT IGNORE INTO musculos (idMusculo, nombreMusc, grupo_muscular)
                VALUES (%s, %s, %s)
            """, (musculo, musculo, "secondary"))
            musculos_insertados.add(musculo)
        cursor.execute("""
            INSERT IGNORE INTO ejercicio_musculo (idEjercicio, idMusculo, rol)
            VALUES (%s, %s, %s)
        """, (ej_id, musculo, 2))  # rol 2 = secundario

conn.commit()
cursor.close()
conn.close()
print(f"✅ {len(ejercicios)} ejercicios importados correctamente")